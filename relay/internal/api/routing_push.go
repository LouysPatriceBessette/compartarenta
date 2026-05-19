package api

import (
	"encoding/hex"
	"encoding/json"
	"io"
	"net/http"
	"time"

	"github.com/compartarenta/relay/internal/store"
)

type pushRegisterRequest struct {
	Provider            string `json:"provider"`
	PushToken           string `json:"push_token"`
	RecipientIdentity   string `json:"recipient_identity"`
	Country             string `json:"country"`
}

type pushRegisterResponse struct {
	ExpiresAt time.Time `json:"expires_at"`
}

type pushUnregisterRequest struct {
	Provider          string `json:"provider"`
	PushToken         string `json:"push_token"`
	RecipientIdentity string `json:"recipient_identity"`
}

func (s *Server) handleRoutingPushRegister(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		writeError(w, http.StatusMethodNotAllowed, "method_not_allowed", "POST only")
		return
	}
	body, err := io.ReadAll(http.MaxBytesReader(w, r.Body, 8192))
	if err != nil {
		s.rejectBadFraming(w, r, "routing_push_register", "oversize")
		return
	}
	var req pushRegisterRequest
	if err := json.Unmarshal(body, &req); err != nil {
		s.rejectBadFraming(w, r, "routing_push_register", "malformed_json")
		return
	}
	recipient, err := decodeIdentity(req.RecipientIdentity, s.idMinLen, s.idMaxLen)
	if err != nil {
		s.rejectBadFraming(w, r, "routing_push_register", err.Error())
		return
	}
	if req.Provider != "fcm" && req.Provider != "apns" {
		s.rejectBadFraming(w, r, "routing_push_register", "invalid_provider")
		return
	}
	if req.PushToken == "" || len(req.PushToken) > 512 {
		s.rejectBadFraming(w, r, "routing_push_register", "invalid_push_token")
		return
	}

	if !s.identityLim.Allow("identity:" + hex.EncodeToString(recipient)) {
		writeError(w, http.StatusTooManyRequests, "rate_limited_identity",
			"per-identity rate limit exceeded")
		return
	}

	ok, err := s.store.HasActiveRoutingForIdentity(r.Context(), recipient)
	if err != nil {
		s.writeInternal(w, r, "routing_push_register", err)
		return
	}
	if !ok {
		s.rejectBadFraming(w, r, "routing_push_register", "no_active_routing")
		return
	}

	country := store.NormalizeCountryCode(req.Country)
	now := s.now()
	expires := now.Add(s.cfg.RoutingPushTokenTTL)
	if err := s.store.UpsertRoutingPushToken(r.Context(), recipient, req.Provider, req.PushToken, country, expires, now); err != nil {
		s.writeInternal(w, r, "routing_push_register", err)
		return
	}
	writeJSON(w, http.StatusOK, pushRegisterResponse{ExpiresAt: expires})
}

func (s *Server) handleRoutingPushUnregister(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		writeError(w, http.StatusMethodNotAllowed, "method_not_allowed", "POST only")
		return
	}
	body, err := io.ReadAll(http.MaxBytesReader(w, r.Body, 8192))
	if err != nil {
		s.rejectBadFraming(w, r, "routing_push_unregister", "oversize")
		return
	}
	var req pushUnregisterRequest
	if err := json.Unmarshal(body, &req); err != nil {
		s.rejectBadFraming(w, r, "routing_push_unregister", "malformed_json")
		return
	}
	recipient, err := decodeIdentity(req.RecipientIdentity, s.idMinLen, s.idMaxLen)
	if err != nil {
		s.rejectBadFraming(w, r, "routing_push_unregister", err.Error())
		return
	}
	if req.Provider != "fcm" && req.Provider != "apns" {
		s.rejectBadFraming(w, r, "routing_push_unregister", "invalid_provider")
		return
	}
	if req.PushToken == "" || len(req.PushToken) > 512 {
		s.rejectBadFraming(w, r, "routing_push_unregister", "invalid_push_token")
		return
	}

	if !s.identityLim.Allow("identity:" + hex.EncodeToString(recipient)) {
		writeError(w, http.StatusTooManyRequests, "rate_limited_identity",
			"per-identity rate limit exceeded")
		return
	}

	ok, err := s.store.HasActiveRoutingForIdentity(r.Context(), recipient)
	if err != nil {
		s.writeInternal(w, r, "routing_push_unregister", err)
		return
	}
	if !ok {
		s.rejectBadFraming(w, r, "routing_push_unregister", "no_active_routing")
		return
	}

	if _, err := s.store.DeleteRoutingPushToken(r.Context(), recipient, req.Provider, req.PushToken); err != nil {
		s.writeInternal(w, r, "routing_push_unregister", err)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}
