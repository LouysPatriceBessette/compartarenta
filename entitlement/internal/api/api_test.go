package api

import (
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"

	"github.com/compartarenta/entitlement/internal/config"
)

func TestValidateInstallationIDBounds(t *testing.T) {
	if _, ok := validateID("short", 8, 64); ok {
		t.Fatal("expected reject short id")
	}
	id := "inst-alpha-device-001"
	if got, ok := validateID(id, 8, 64); !ok || got != id {
		t.Fatalf("got %q %v", got, ok)
	}
}

func TestIntrospectUnauthorizedWithoutToken(t *testing.T) {
	cfg := config.Config{InternalToken: "secret", IDMinLen: 8, IDMaxLen: 64}
	s := NewServer(cfg, nil)
	req := httptest.NewRequest(http.MethodPost, "/v1/introspect/envelope", nil)
	rr := httptest.NewRecorder()
	s.Handler().ServeHTTP(rr, req)
	if rr.Code != http.StatusUnauthorized {
		t.Fatalf("status=%d", rr.Code)
	}
}

func TestMigrateInstallationUnauthorizedWithoutToken(t *testing.T) {
	cfg := config.Config{InternalToken: "secret", IDMinLen: 8, IDMaxLen: 64}
	s := NewServer(cfg, nil)
	req := httptest.NewRequest(http.MethodPost, "/v1/installations/migrate", nil)
	rr := httptest.NewRecorder()
	s.Handler().ServeHTTP(rr, req)
	if rr.Code != http.StatusUnauthorized {
		t.Fatalf("status=%d", rr.Code)
	}
}

func TestMigrateInstallationRejectsInvalidEnvelopeKind(t *testing.T) {
	cfg := config.Config{InternalToken: "secret", IDMinLen: 8, IDMaxLen: 64}
	s := NewServer(cfg, nil)
	body := `{"plan_id":"plan:a","old_participant_installation_id":"inst-old-device","new_participant_installation_id":"inst-new-device","envelope_kind":13}`
	req := httptest.NewRequest(http.MethodPost, "/v1/installations/migrate", strings.NewReader(body))
	req.Header.Set("Authorization", "Bearer secret")
	req.Header.Set("Content-Type", "application/json")
	rr := httptest.NewRecorder()
	s.Handler().ServeHTTP(rr, req)
	if rr.Code != http.StatusBadRequest {
		t.Fatalf("status=%d body=%s", rr.Code, rr.Body.String())
	}
}
