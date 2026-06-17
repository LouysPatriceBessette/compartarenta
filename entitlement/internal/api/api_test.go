package api

import (
	"net/http"
	"net/http/httptest"
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
