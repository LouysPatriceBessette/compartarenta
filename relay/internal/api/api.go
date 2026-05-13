// Package api implements the HTTP surface of the relay.
//
// Every handler enforces framing, size limit, and rate limit before
// touching the database. The handlers never log ciphertext or anything
// derived from it; only opaque identifiers, timing, and error classes
// reach the structured logger (`relay-observability-without-plaintext`
// / "Logs do not contain user-content plaintext").
package api

import (
	"context"
	"crypto/rand"
	"encoding/base64"
	"encoding/hex"
	"encoding/json"
	"errors"
	"io"
	"net"
	"net/http"
	"strconv"
	"strings"
	"time"

	"github.com/jackc/pgx/v5"

	"github.com/compartarenta/relay/internal/config"
	"github.com/compartarenta/relay/internal/logging"
	"github.com/compartarenta/relay/internal/metrics"
	"github.com/compartarenta/relay/internal/ratelimit"
	"github.com/compartarenta/relay/internal/store"
	"github.com/compartarenta/relay/internal/version"
)

// Server bundles the dependencies the HTTP layer needs.
type Server struct {
	cfg          config.Config
	store        *store.Store
	logger       *logging.Logger
	identityLim  *ratelimit.Limiter
	ipLim        *ratelimit.Limiter
	now          func() time.Time
	idMinLen     int
	idMaxLen     int
	envelopeIDFn func() ([]byte, error)
}

// NewServer constructs a fully-wired Server. The identity / IP rate
// limiters are owned by the server and live for the process lifetime.
func NewServer(cfg config.Config, st *store.Store, l *logging.Logger) *Server {
	return &Server{
		cfg:          cfg,
		store:        st,
		logger:       l,
		identityLim:  ratelimit.New(cfg.RateLimitPerIdentity),
		ipLim:        ratelimit.New(cfg.RateLimitPerIP),
		now:          time.Now,
		idMinLen:     8,
		idMaxLen:     64,
		envelopeIDFn: randomEnvelopeID,
	}
}

// PublicHandler returns the http.Handler bound to the public listener.
// It exposes the relay protocol endpoints plus /healthz and /readyz.
func (s *Server) PublicHandler() http.Handler {
	mux := http.NewServeMux()
	mux.HandleFunc("/v1/envelopes", s.handleEnvelopes)
	mux.HandleFunc("/v1/envelopes/", s.handleEnvelopeSubResource)
	mux.HandleFunc("/v1/inbox/", s.handleInbox)
	mux.HandleFunc("/v1/disconnect", s.handleDisconnect)
	mux.HandleFunc("/v1/handshake/establish", s.handleEstablishRouting)
	mux.HandleFunc("/healthz", s.handleHealthz)
	mux.HandleFunc("/readyz", s.handleReadyz)
	mux.HandleFunc("/", s.handleNotFound)
	return s.cors(s.middleware(mux))
}

// cors wraps a handler with CORS handling for browser callers.
//
// Behaviour:
//   - When `CORS_ALLOWED_ORIGINS` is empty (default), the middleware is a
//     no-op and browser clients are blocked at the same-origin boundary,
//     same as before this feature existed.
//   - When configured, the middleware adds `Access-Control-Allow-Origin`
//     on every response whose `Origin` matches the allow-list (echoing
//     the request's origin exactly, or `*` if the operator opted in to
//     wildcarding). It also handles CORS preflight (`OPTIONS`) requests
//     directly with a 204 response and the appropriate
//     `Access-Control-Allow-Methods` / `Access-Control-Allow-Headers` /
//     `Access-Control-Max-Age` headers.
//   - Responses always carry `Vary: Origin` when CORS is active, so
//     caches don't smush together responses across different callers.
func (s *Server) cors(next http.Handler) http.Handler {
	allowed := s.cfg.CORSAllowedOrigins
	if len(allowed) == 0 {
		return next
	}
	wildcard := false
	allowSet := make(map[string]struct{}, len(allowed))
	for _, o := range allowed {
		if o == "*" {
			wildcard = true
			continue
		}
		allowSet[o] = struct{}{}
	}
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		origin := r.Header.Get("Origin")
		allow := ""
		switch {
		case origin == "":
			// Non-browser caller: don't bother emitting CORS headers.
		case wildcard:
			allow = "*"
		default:
			if _, ok := allowSet[origin]; ok {
				allow = origin
			}
		}
		if allow != "" {
			w.Header().Set("Access-Control-Allow-Origin", allow)
			w.Header().Add("Vary", "Origin")
		}
		if r.Method == http.MethodOptions && origin != "" {
			// Preflight: short-circuit even when the origin does not
			// match so the browser surfaces a clear "blocked" error
			// rather than the generic "Failed to fetch".
			if allow != "" {
				reqHeaders := r.Header.Get("Access-Control-Request-Headers")
				if reqHeaders == "" {
					reqHeaders = "content-type"
				}
				w.Header().Set("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
				w.Header().Set("Access-Control-Allow-Headers", reqHeaders)
				w.Header().Set("Access-Control-Max-Age", "600")
			}
			w.WriteHeader(http.StatusNoContent)
			return
		}
		next.ServeHTTP(w, r)
	})
}

// SetClock replaces the wall-clock source. Tests only.
func (s *Server) SetClock(now func() time.Time) {
	s.now = now
}

// SetEnvelopeIDFunc replaces the envelope-id generator. Tests only.
func (s *Server) SetEnvelopeIDFunc(fn func() ([]byte, error)) {
	s.envelopeIDFn = fn
}

func (s *Server) middleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		start := s.now()
		ip := remoteIP(r)
		endpoint := classifyEndpoint(r)
		ww := &statusRecorder{ResponseWriter: w, status: 200}

		// Per-IP rate limit applies to every protocol endpoint. Health
		// and readiness probes are exempt so a container runtime can
		// still verify liveness during a flood.
		if endpoint != "healthz" && endpoint != "readyz" {
			if !s.ipLim.Allow(ip) {
				metrics.RateLimitRejections.WithLabelValues("ip").Inc()
				writeError(w, http.StatusTooManyRequests, "rate_limited_ip", "per-IP rate limit exceeded")
				s.logRejection(r.Context(), endpoint, "rate_limited_ip", time.Since(start))
				return
			}
		}
		next.ServeHTTP(ww, r)

		dur := time.Since(start)
		metrics.HTTPRequests.WithLabelValues(endpoint, statusClass(ww.status)).Inc()
		metrics.HTTPLatencySeconds.WithLabelValues(endpoint).Observe(dur.Seconds())
		s.logger.Info(r.Context(), "http.request",
			logging.F(logging.KeyEndpoint, endpoint),
			logging.F(logging.KeyMethod, r.Method),
			logging.F(logging.KeyStatus, ww.status),
			logging.F(logging.KeyDurationMS, dur.Milliseconds()),
		)
	})
}

// ---------------------------------------------------------------------------
// POST /v1/envelopes
// ---------------------------------------------------------------------------

type envelopeRequest struct {
	SenderIdentity    string `json:"sender_identity"`
	RecipientIdentity string `json:"recipient_identity"`
	IdempotencyKey    string `json:"idempotency_key"`
	Ciphertext        string `json:"ciphertext"`
	Kind              int    `json:"kind"`
	TTLSeconds        int    `json:"ttl_seconds"`
}

type envelopeResponse struct {
	EnvelopeID   string    `json:"envelope_id"`
	TTLExpiresAt time.Time `json:"ttl_expires_at"`
	Replay       bool      `json:"replay"`
}

func (s *Server) handleEnvelopes(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		writeError(w, http.StatusMethodNotAllowed, "method_not_allowed", "POST only")
		return
	}
	body, err := io.ReadAll(http.MaxBytesReader(w, r.Body,
		int64(s.cfg.EnvelopeMaxBytes)+envelopeJSONOverhead))
	if err != nil {
		metrics.HTTPRejections.WithLabelValues("envelopes", "oversize_or_io").Inc()
		writeError(w, http.StatusRequestEntityTooLarge, "oversize", "request too large")
		return
	}
	var req envelopeRequest
	if err := json.Unmarshal(body, &req); err != nil {
		s.rejectBadFraming(w, r, "envelopes", "malformed_json")
		return
	}

	sender, err1 := decodeIdentity(req.SenderIdentity, s.idMinLen, s.idMaxLen)
	recipient, err2 := decodeIdentity(req.RecipientIdentity, s.idMinLen, s.idMaxLen)
	idemKey, err3 := decodeIdentity(req.IdempotencyKey, s.idMinLen, s.idMaxLen)
	ciphertext, err4 := decodeCiphertext(req.Ciphertext, s.cfg.EnvelopeMaxBytes)
	if firstErr := firstNonNil(err1, err2, err3, err4); firstErr != nil {
		s.rejectBadFraming(w, r, "envelopes", firstErr.Error())
		return
	}
	if req.Kind < 0 || req.Kind > 255 {
		s.rejectBadFraming(w, r, "envelopes", "kind_out_of_range")
		return
	}
	ttl := s.clampTTL(time.Duration(req.TTLSeconds) * time.Second)

	if !s.identityLim.Allow("identity:" + hex.EncodeToString(sender)) {
		metrics.RateLimitRejections.WithLabelValues("identity").Inc()
		writeError(w, http.StatusTooManyRequests, "rate_limited_identity",
			"per-identity rate limit exceeded")
		return
	}

	ok, err := s.store.HasRouting(r.Context(), sender, recipient)
	if err != nil {
		s.writeInternal(w, r, "envelopes", err)
		return
	}
	if !ok {
		s.rejectBadFraming(w, r, "envelopes", "no_routing_relationship")
		return
	}

	envelopeID, err := s.envelopeIDFn()
	if err != nil {
		s.writeInternal(w, r, "envelopes", err)
		return
	}
	now := s.now()
	storedID, replay, err := s.store.LookupOrReserveIdempotency(
		r.Context(), sender, idemKey, envelopeID, s.cfg.IdempotencyTTL, now)
	if err != nil {
		s.writeInternal(w, r, "envelopes", err)
		return
	}
	if replay {
		writeJSON(w, http.StatusOK, envelopeResponse{
			EnvelopeID:   base64.RawURLEncoding.EncodeToString(storedID),
			TTLExpiresAt: now.Add(s.cfg.IdempotencyTTL),
			Replay:       true,
		})
		return
	}

	err = s.store.StoreEnvelope(r.Context(), store.Envelope{
		EnvelopeID:        storedID,
		SenderIdentity:    sender,
		RecipientIdentity: recipient,
		Ciphertext:        ciphertext,
		Kind:              req.Kind,
		CreatedAt:         now,
		TTLExpiresAt:      now.Add(ttl),
	})
	if err != nil {
		s.writeInternal(w, r, "envelopes", err)
		return
	}
	_ = s.store.TouchRouting(r.Context(), sender, recipient)
	metrics.EnvelopesAccepted.Inc()
	writeJSON(w, http.StatusCreated, envelopeResponse{
		EnvelopeID:   base64.RawURLEncoding.EncodeToString(storedID),
		TTLExpiresAt: now.Add(ttl),
		Replay:       false,
	})

	s.logger.Info(r.Context(), "envelope.accepted",
		logging.F(logging.KeyEndpoint, "envelopes"),
		logging.Bytes(logging.KeyEnvelopeID, storedID),
		logging.Bytes(logging.KeySenderIdentity, sender),
		logging.Bytes(logging.KeyRecipientIdent, recipient),
	)
}

// ---------------------------------------------------------------------------
// POST /v1/envelopes/:id/ack
// ---------------------------------------------------------------------------

func (s *Server) handleEnvelopeSubResource(w http.ResponseWriter, r *http.Request) {
	const prefix = "/v1/envelopes/"
	rest := strings.TrimPrefix(r.URL.Path, prefix)
	parts := strings.SplitN(rest, "/", 2)
	if len(parts) != 2 || parts[1] != "ack" {
		s.handleNotFound(w, r)
		return
	}
	if r.Method != http.MethodPost {
		writeError(w, http.StatusMethodNotAllowed, "method_not_allowed", "POST only")
		return
	}
	envelopeID, err := decodeIdentity(parts[0], s.idMinLen, s.idMaxLen)
	if err != nil {
		s.rejectBadFraming(w, r, "envelopes_ack", err.Error())
		return
	}

	body, err := io.ReadAll(http.MaxBytesReader(w, r.Body, 512))
	if err != nil {
		s.rejectBadFraming(w, r, "envelopes_ack", "oversize")
		return
	}
	var req struct {
		RecipientIdentity string `json:"recipient_identity"`
	}
	if err := json.Unmarshal(body, &req); err != nil {
		s.rejectBadFraming(w, r, "envelopes_ack", "malformed_json")
		return
	}
	recipient, err := decodeIdentity(req.RecipientIdentity, s.idMinLen, s.idMaxLen)
	if err != nil {
		s.rejectBadFraming(w, r, "envelopes_ack", err.Error())
		return
	}

	deleted, err := s.store.AckEnvelope(r.Context(), envelopeID, recipient)
	if err != nil {
		s.writeInternal(w, r, "envelopes_ack", err)
		return
	}
	if !deleted {
		writeError(w, http.StatusNotFound, "not_found",
			"no envelope addressed to that recipient with that id")
		return
	}
	metrics.EnvelopesDelivered.Inc()
	w.WriteHeader(http.StatusNoContent)
	s.logger.Info(r.Context(), "envelope.delivered",
		logging.F(logging.KeyEndpoint, "envelopes_ack"),
		logging.Bytes(logging.KeyEnvelopeID, envelopeID),
		logging.Bytes(logging.KeyRecipientIdent, recipient),
	)
}

// ---------------------------------------------------------------------------
// GET /v1/inbox/:recipient
// ---------------------------------------------------------------------------

type inboxResponse struct {
	Envelopes []envelopeView `json:"envelopes"`
}

type envelopeView struct {
	EnvelopeID        string    `json:"envelope_id"`
	SenderIdentity    string    `json:"sender_identity"`
	RecipientIdentity string    `json:"recipient_identity"`
	Ciphertext        string    `json:"ciphertext"`
	Kind              int       `json:"kind"`
	CreatedAt         time.Time `json:"created_at"`
	TTLExpiresAt      time.Time `json:"ttl_expires_at"`
}

func (s *Server) handleInbox(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		writeError(w, http.StatusMethodNotAllowed, "method_not_allowed", "GET only")
		return
	}
	rest := strings.TrimPrefix(r.URL.Path, "/v1/inbox/")
	recipient, err := decodeIdentity(rest, s.idMinLen, s.idMaxLen)
	if err != nil {
		s.rejectBadFraming(w, r, "inbox", err.Error())
		return
	}
	limit := 32
	if q := r.URL.Query().Get("limit"); q != "" {
		n, err := strconv.Atoi(q)
		if err != nil || n < 1 || n > 128 {
			s.rejectBadFraming(w, r, "inbox", "invalid_limit")
			return
		}
		limit = n
	}
	rows, err := s.store.FetchInbox(r.Context(), recipient, limit)
	if err != nil {
		s.writeInternal(w, r, "inbox", err)
		return
	}
	views := make([]envelopeView, 0, len(rows))
	for _, e := range rows {
		views = append(views, envelopeView{
			EnvelopeID:        base64.RawURLEncoding.EncodeToString(e.EnvelopeID),
			SenderIdentity:    base64.RawURLEncoding.EncodeToString(e.SenderIdentity),
			RecipientIdentity: base64.RawURLEncoding.EncodeToString(e.RecipientIdentity),
			Ciphertext:        base64.RawURLEncoding.EncodeToString(e.Ciphertext),
			Kind:              e.Kind,
			CreatedAt:         e.CreatedAt,
			TTLExpiresAt:      e.TTLExpiresAt,
		})
	}
	writeJSON(w, http.StatusOK, inboxResponse{Envelopes: views})
}

// ---------------------------------------------------------------------------
// POST /v1/handshake/establish
// ---------------------------------------------------------------------------
//
// The Contacts handshake (client-side, in `contacts-module`) negotiates
// peer keys end-to-end. When both clients are satisfied with the
// handshake outcome, they each call this endpoint with their own
// opaque routing identifier and the peer's opaque routing identifier;
// the relay records the relationship so subsequent envelopes are
// admitted. The relay does not inspect or verify the handshake content
// itself.

type establishRequest struct {
	SelfIdentity string `json:"self_identity"`
	PeerIdentity string `json:"peer_identity"`
}

func (s *Server) handleEstablishRouting(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		writeError(w, http.StatusMethodNotAllowed, "method_not_allowed", "POST only")
		return
	}
	body, err := io.ReadAll(http.MaxBytesReader(w, r.Body, 4096))
	if err != nil {
		s.rejectBadFraming(w, r, "handshake_establish", "oversize")
		return
	}
	var req establishRequest
	if err := json.Unmarshal(body, &req); err != nil {
		s.rejectBadFraming(w, r, "handshake_establish", "malformed_json")
		return
	}
	self, err := decodeIdentity(req.SelfIdentity, s.idMinLen, s.idMaxLen)
	if err != nil {
		s.rejectBadFraming(w, r, "handshake_establish", err.Error())
		return
	}
	peer, err := decodeIdentity(req.PeerIdentity, s.idMinLen, s.idMaxLen)
	if err != nil {
		s.rejectBadFraming(w, r, "handshake_establish", err.Error())
		return
	}
	if !s.identityLim.Allow("identity:" + hex.EncodeToString(self)) {
		metrics.RateLimitRejections.WithLabelValues("identity").Inc()
		writeError(w, http.StatusTooManyRequests, "rate_limited_identity",
			"per-identity rate limit exceeded")
		return
	}
	if err := s.store.EstablishRouting(r.Context(), self, peer); err != nil {
		s.writeInternal(w, r, "handshake_establish", err)
		return
	}
	metrics.RoutingCreated.Inc()
	w.WriteHeader(http.StatusNoContent)
}

// ---------------------------------------------------------------------------
// POST /v1/disconnect
// ---------------------------------------------------------------------------

type disconnectRequest struct {
	SelfIdentity string `json:"self_identity"`
	PeerIdentity string `json:"peer_identity"`
}

func (s *Server) handleDisconnect(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		writeError(w, http.StatusMethodNotAllowed, "method_not_allowed", "POST only")
		return
	}
	body, err := io.ReadAll(http.MaxBytesReader(w, r.Body, 4096))
	if err != nil {
		s.rejectBadFraming(w, r, "disconnect", "oversize")
		return
	}
	var req disconnectRequest
	if err := json.Unmarshal(body, &req); err != nil {
		s.rejectBadFraming(w, r, "disconnect", "malformed_json")
		return
	}
	self, err := decodeIdentity(req.SelfIdentity, s.idMinLen, s.idMaxLen)
	if err != nil {
		s.rejectBadFraming(w, r, "disconnect", err.Error())
		return
	}
	peer, err := decodeIdentity(req.PeerIdentity, s.idMinLen, s.idMaxLen)
	if err != nil {
		s.rejectBadFraming(w, r, "disconnect", err.Error())
		return
	}
	transitioned, err := s.store.MarkDisconnecting(r.Context(), self, peer, s.now())
	if err != nil {
		s.writeInternal(w, r, "disconnect", err)
		return
	}
	if !transitioned {
		writeError(w, http.StatusNotFound, "not_found", "no active routing relationship")
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

// ---------------------------------------------------------------------------
// Health / readiness
// ---------------------------------------------------------------------------

type healthResponse struct {
	Status        string `json:"status"`
	Build         string `json:"build"`
	SchemaVersion int    `json:"schema_version"`
}

func (s *Server) handleHealthz(w http.ResponseWriter, r *http.Request) {
	writeJSON(w, http.StatusOK, healthResponse{
		Status:        "ok",
		Build:         version.Build,
		SchemaVersion: version.Expected,
	})
}

func (s *Server) handleReadyz(w http.ResponseWriter, r *http.Request) {
	ctx, cancel := context.WithTimeout(r.Context(), 2*time.Second)
	defer cancel()
	v, err := s.store.SchemaVersion(ctx)
	if err != nil {
		writeError(w, http.StatusServiceUnavailable, "degraded", "db unavailable")
		return
	}
	if v != version.Expected {
		writeError(w, http.StatusServiceUnavailable, "starting", "schema not at expected version")
		return
	}
	writeJSON(w, http.StatusOK, healthResponse{
		Status:        "ready",
		Build:         version.Build,
		SchemaVersion: v,
	})
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

func (s *Server) handleNotFound(w http.ResponseWriter, r *http.Request) {
	writeError(w, http.StatusNotFound, "not_found", "no such endpoint")
}

func (s *Server) rejectBadFraming(w http.ResponseWriter, r *http.Request, endpoint, reason string) {
	metrics.HTTPRejections.WithLabelValues(endpoint, reason).Inc()
	s.logRejection(r.Context(), endpoint, reason, 0)
	writeError(w, http.StatusBadRequest, "bad_envelope", reason)
}

func (s *Server) writeInternal(w http.ResponseWriter, r *http.Request, endpoint string, err error) {
	if errors.Is(err, pgx.ErrTxClosed) || errors.Is(err, context.Canceled) {
		writeError(w, http.StatusServiceUnavailable, "shutting_down", "service shutting down")
		return
	}
	s.logger.Error(r.Context(), "internal_error",
		logging.F(logging.KeyEndpoint, endpoint),
		logging.F(logging.KeyError, err.Error()),
	)
	metrics.HTTPRejections.WithLabelValues(endpoint, "internal").Inc()
	writeError(w, http.StatusInternalServerError, "internal", "internal error")
}

func (s *Server) logRejection(ctx context.Context, endpoint, reason string, dur time.Duration) {
	s.logger.Warn(ctx, "http.rejection",
		logging.F(logging.KeyEndpoint, endpoint),
		logging.F(logging.KeyRejectionReason, reason),
		logging.F(logging.KeyDurationMS, dur.Milliseconds()),
	)
}

func (s *Server) clampTTL(d time.Duration) time.Duration {
	if d < s.cfg.EnvelopeTTLMin {
		return s.cfg.EnvelopeTTLMin
	}
	if d > s.cfg.EnvelopeTTLMax {
		return s.cfg.EnvelopeTTLMax
	}
	return d
}

const envelopeJSONOverhead = 2048

func writeJSON(w http.ResponseWriter, status int, v any) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(v)
}

type errorBody struct {
	Code   string `json:"code"`
	Detail string `json:"detail,omitempty"`
}

func writeError(w http.ResponseWriter, status int, code, detail string) {
	writeJSON(w, status, errorBody{Code: code, Detail: detail})
}

func decodeIdentity(s string, min, max int) ([]byte, error) {
	if s == "" {
		return nil, errors.New("empty_identity")
	}
	b, err := base64.RawURLEncoding.DecodeString(s)
	if err != nil {
		return nil, errors.New("invalid_base64_identity")
	}
	if len(b) < min || len(b) > max {
		return nil, errors.New("identity_length")
	}
	return b, nil
}

func decodeCiphertext(s string, maxBytes int) ([]byte, error) {
	if s == "" {
		return nil, errors.New("empty_ciphertext")
	}
	b, err := base64.RawURLEncoding.DecodeString(s)
	if err != nil {
		return nil, errors.New("invalid_base64_ciphertext")
	}
	if len(b) == 0 {
		return nil, errors.New("empty_ciphertext")
	}
	if len(b) > maxBytes {
		return nil, errors.New("ciphertext_too_large")
	}
	return b, nil
}

func firstNonNil(errs ...error) error {
	for _, e := range errs {
		if e != nil {
			return e
		}
	}
	return nil
}

func remoteIP(r *http.Request) string {
	if xff := r.Header.Get("X-Forwarded-For"); xff != "" {
		if comma := strings.IndexByte(xff, ','); comma >= 0 {
			return strings.TrimSpace(xff[:comma])
		}
		return strings.TrimSpace(xff)
	}
	host, _, err := net.SplitHostPort(r.RemoteAddr)
	if err != nil {
		return r.RemoteAddr
	}
	return host
}

func statusClass(s int) string {
	switch {
	case s >= 500:
		return "5xx"
	case s >= 400:
		return "4xx"
	case s >= 300:
		return "3xx"
	case s >= 200:
		return "2xx"
	default:
		return "1xx"
	}
}

func classifyEndpoint(r *http.Request) string {
	p := r.URL.Path
	switch {
	case p == "/v1/envelopes":
		return "envelopes"
	case strings.HasPrefix(p, "/v1/envelopes/") && strings.HasSuffix(p, "/ack"):
		return "envelopes_ack"
	case strings.HasPrefix(p, "/v1/inbox/"):
		return "inbox"
	case p == "/v1/disconnect":
		return "disconnect"
	case p == "/v1/handshake/establish":
		return "handshake_establish"
	case p == "/healthz":
		return "healthz"
	case p == "/readyz":
		return "readyz"
	default:
		return "other"
	}
}

type statusRecorder struct {
	http.ResponseWriter
	status int
}

func (s *statusRecorder) WriteHeader(code int) {
	s.status = code
	s.ResponseWriter.WriteHeader(code)
}

func randomEnvelopeID() ([]byte, error) {
	b := make([]byte, 16)
	if _, err := rand.Read(b); err != nil {
		return nil, err
	}
	return b, nil
}
