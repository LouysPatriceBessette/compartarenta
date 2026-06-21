//go:build integration

package integration

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"

	"github.com/compartarenta/relay/internal/api"
	"github.com/compartarenta/relay/internal/logging"
	"github.com/compartarenta/relay/internal/store"
)

type pushTokenRow struct {
	Country    string
	ExpiresAt  time.Time
	LastSeenAt time.Time
}

func setupRoutingPushIntegration(t *testing.T) (context.Context, *store.Store, *api.Server, http.Handler) {
	t.Helper()
	ctx := context.Background()
	dsn := integrationDSN(t)

	st, err := store.New(ctx, dsn)
	if err != nil {
		t.Fatalf("store.New: %v", err)
	}
	t.Cleanup(func() { st.Close() })
	resetRelayData(ctx, t, dsn)

	cfg := testConfig(dsn)
	srv := api.NewServer(cfg, st, logging.NewForTest(), nil)
	return ctx, st, srv, srv.PublicHandler()
}

func postRoutingPushRegister(t *testing.T, h http.Handler, body map[string]any) *httptest.ResponseRecorder {
	t.Helper()
	payload, err := json.Marshal(body)
	if err != nil {
		t.Fatalf("marshal register body: %v", err)
	}
	req := httptest.NewRequest(http.MethodPost, "/v1/routing/push/register", bytes.NewReader(payload))
	req.Header.Set("Content-Type", "application/json")
	rr := httptest.NewRecorder()
	h.ServeHTTP(rr, req)
	return rr
}

func postRoutingPushUnregister(t *testing.T, h http.Handler, body map[string]any) *httptest.ResponseRecorder {
	t.Helper()
	payload, err := json.Marshal(body)
	if err != nil {
		t.Fatalf("marshal unregister body: %v", err)
	}
	req := httptest.NewRequest(http.MethodPost, "/v1/routing/push/unregister", bytes.NewReader(payload))
	req.Header.Set("Content-Type", "application/json")
	rr := httptest.NewRecorder()
	h.ServeHTTP(rr, req)
	return rr
}

func fetchPushTokenRow(
	ctx context.Context,
	dsn string,
	recipient []byte,
	provider, pushToken string,
) (pushTokenRow, bool, error) {
	pool, err := pgxpool.New(ctx, dsn)
	if err != nil {
		return pushTokenRow{}, false, err
	}
	defer pool.Close()

	var row pushTokenRow
	err = pool.QueryRow(ctx, `
		SELECT country, expires_at, last_seen_at
		FROM routing_push_tokens
		WHERE recipient_routing_id = $1 AND provider = $2 AND push_token = $3
	`, recipient, provider, pushToken).Scan(&row.Country, &row.ExpiresAt, &row.LastSeenAt)
	if errors.Is(err, pgx.ErrNoRows) {
		return pushTokenRow{}, false, nil
	}
	if err != nil {
		return pushTokenRow{}, false, err
	}
	return row, true, nil
}

func countPushTokens(ctx context.Context, dsn string) (int64, error) {
	pool, err := pgxpool.New(ctx, dsn)
	if err != nil {
		return 0, err
	}
	defer pool.Close()
	var n int64
	err = pool.QueryRow(ctx, `SELECT COUNT(*) FROM routing_push_tokens`).Scan(&n)
	return n, err
}

func parseRegisterExpiresAt(t *testing.T, rr *httptest.ResponseRecorder) time.Time {
	t.Helper()
	var resp struct {
		ExpiresAt time.Time `json:"expires_at"`
	}
	if err := json.Unmarshal(rr.Body.Bytes(), &resp); err != nil {
		t.Fatalf("decode register response: %v body %s", err, rr.Body.String())
	}
	if resp.ExpiresAt.IsZero() {
		t.Fatalf("empty expires_at in %s", rr.Body.String())
	}
	return resp.ExpiresAt.UTC()
}

func assertAPIError(t *testing.T, rr *httptest.ResponseRecorder, status int, code, detail string) {
	t.Helper()
	if rr.Code != status {
		t.Fatalf("status %d want %d body %s", rr.Code, status, rr.Body.String())
	}
	var errBody struct {
		Code   string `json:"code"`
		Detail string `json:"detail"`
	}
	if err := json.Unmarshal(rr.Body.Bytes(), &errBody); err != nil {
		t.Fatalf("decode error body: %v", err)
	}
	if errBody.Code != code {
		t.Fatalf("code %q want %q", errBody.Code, code)
	}
	if errBody.Detail != detail {
		t.Fatalf("detail %q want %q", errBody.Detail, detail)
	}
}

// TestIntegrationRoutingPushRegisterUnregister (OpenSpec closed-app-push-delivery 3.4)
// covers authenticated register, TTL refresh, unregister deletion, and country handling.
func TestIntegrationRoutingPushRegisterUnregister(t *testing.T) {
	ctx, st, srv, h := setupRoutingPushIntegration(t)
	dsn := integrationDSN(t)

	sender := mustDecodeB64ID(t, b64ID(0x10, 8))
	recipient := mustDecodeB64ID(t, b64ID(0x20, 8))
	recipientB64 := b64ID(0x20, 8)
	if err := st.EstablishRouting(ctx, sender, recipient); err != nil {
		t.Fatalf("EstablishRouting: %v", err)
	}

	const (
		provider  = "fcm"
		pushToken = "integration-test-token"
	)

	t0 := time.Date(2026, 6, 21, 10, 0, 0, 0, time.UTC)
	srv.SetClock(func() time.Time { return t0 })
	ttl := testConfig(dsn).RoutingPushTokenTTL

	// Authenticated success with accepted country.
	rr := postRoutingPushRegister(t, h, map[string]any{
		"provider":           provider,
		"push_token":         pushToken,
		"recipient_identity": recipientB64,
		"country":            "ca",
	})
	if rr.Code != http.StatusOK {
		t.Fatalf("register: status %d body %s", rr.Code, rr.Body.String())
	}
	expires1 := parseRegisterExpiresAt(t, rr)
	wantExpires1 := t0.Add(ttl)
	if !expires1.Equal(wantExpires1) {
		t.Fatalf("expires_at %v want %v", expires1, wantExpires1)
	}
	row, ok, err := fetchPushTokenRow(ctx, dsn, recipient, provider, pushToken)
	if err != nil {
		t.Fatalf("fetchPushTokenRow: %v", err)
	}
	if !ok {
		t.Fatal("expected routing push token row after register")
	}
	if row.Country != "CA" {
		t.Fatalf("country %q want CA", row.Country)
	}
	if !row.ExpiresAt.UTC().Equal(wantExpires1) {
		t.Fatalf("db expires_at %v want %v", row.ExpiresAt.UTC(), wantExpires1)
	}
	if !row.LastSeenAt.UTC().Equal(t0) {
		t.Fatalf("db last_seen_at %v want %v", row.LastSeenAt.UTC(), t0)
	}

	// TTL refresh on re-register advances expires_at and last_seen_at.
	t1 := t0.Add(24 * time.Hour)
	srv.SetClock(func() time.Time { return t1 })
	rr = postRoutingPushRegister(t, h, map[string]any{
		"provider":           provider,
		"push_token":         pushToken,
		"recipient_identity": recipientB64,
		"country":            "CA",
	})
	if rr.Code != http.StatusOK {
		t.Fatalf("re-register: status %d body %s", rr.Code, rr.Body.String())
	}
	expires2 := parseRegisterExpiresAt(t, rr)
	wantExpires2 := t1.Add(ttl)
	if !expires2.Equal(wantExpires2) {
		t.Fatalf("refreshed expires_at %v want %v", expires2, wantExpires2)
	}
	row, ok, err = fetchPushTokenRow(ctx, dsn, recipient, provider, pushToken)
	if err != nil {
		t.Fatalf("fetchPushTokenRow after refresh: %v", err)
	}
	if !ok {
		t.Fatal("row missing after refresh")
	}
	if !row.ExpiresAt.UTC().Equal(wantExpires2) {
		t.Fatalf("db refreshed expires_at %v want %v", row.ExpiresAt.UTC(), wantExpires2)
	}
	if !row.LastSeenAt.UTC().Equal(t1) {
		t.Fatalf("db refreshed last_seen_at %v want %v", row.LastSeenAt.UTC(), t1)
	}

	n, err := countPushTokens(ctx, dsn)
	if err != nil {
		t.Fatalf("countPushTokens: %v", err)
	}
	if n != 1 {
		t.Fatalf("token row count want 1 got %d", n)
	}

	// Unregister deletes the row.
	unRR := postRoutingPushUnregister(t, h, map[string]any{
		"provider":           provider,
		"push_token":         pushToken,
		"recipient_identity": recipientB64,
	})
	if unRR.Code != http.StatusNoContent {
		t.Fatalf("unregister: status %d body %s", unRR.Code, unRR.Body.String())
	}
	_, ok, err = fetchPushTokenRow(ctx, dsn, recipient, provider, pushToken)
	if err != nil {
		t.Fatalf("fetchPushTokenRow after unregister: %v", err)
	}
	if ok {
		t.Fatal("row should be deleted after unregister")
	}
}

func TestIntegrationRoutingPushRegisterUnauthenticated(t *testing.T) {
	_, _, _, h := setupRoutingPushIntegration(t)

	rr := postRoutingPushRegister(t, h, map[string]any{
		"provider":           "fcm",
		"push_token":         "orphan-token",
		"recipient_identity": b64ID(0x99, 8),
		"country":            "UNDISCLOSED",
	})
	assertAPIError(t, rr, http.StatusBadRequest, "bad_envelope", "no_active_routing")

	n, err := countPushTokens(context.Background(), integrationDSN(t))
	if err != nil {
		t.Fatalf("countPushTokens: %v", err)
	}
	if n != 0 {
		t.Fatalf("unauthenticated register stored rows: got %d", n)
	}
}

func TestIntegrationRoutingPushRegisterCountryNormalization(t *testing.T) {
	ctx, st, _, h := setupRoutingPushIntegration(t)
	dsn := integrationDSN(t)

	sender := mustDecodeB64ID(t, b64ID(0x31, 8))
	recipient := mustDecodeB64ID(t, b64ID(0x32, 8))
	recipientB64 := b64ID(0x32, 8)
	if err := st.EstablishRouting(ctx, sender, recipient); err != nil {
		t.Fatalf("EstablishRouting: %v", err)
	}

	cases := []struct {
		name       string
		country    string
		wantStored string
	}{
		{"UNDISCLOSED accepted", "UNDISCLOSED", "UNDISCLOSED"},
		{"invalid coerced", "not-a-country", "UNDISCLOSED"},
		{"empty coerced", "", "UNDISCLOSED"},
	}
	for i, c := range cases {
		t.Run(c.name, func(t *testing.T) {
			token := "country-case-token-" + string(rune('a'+i))
			rr := postRoutingPushRegister(t, h, map[string]any{
				"provider":           "fcm",
				"push_token":         token,
				"recipient_identity": recipientB64,
				"country":            c.country,
			})
			if rr.Code != http.StatusOK {
				t.Fatalf("register: status %d body %s", rr.Code, rr.Body.String())
			}
			row, ok, err := fetchPushTokenRow(ctx, dsn, recipient, "fcm", token)
			if err != nil {
				t.Fatalf("fetchPushTokenRow: %v", err)
			}
			if !ok {
				t.Fatal("expected row")
			}
			if row.Country != c.wantStored {
				t.Fatalf("country %q want %q", row.Country, c.wantStored)
			}
		})
	}
}
