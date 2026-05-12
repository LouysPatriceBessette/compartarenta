package api

import (
	"errors"
	"strings"
	"testing"
	"time"

	"github.com/compartarenta/relay/internal/config"
)

func TestDecodeIdentityRejectsEmpty(t *testing.T) {
	if _, err := decodeIdentity("", 8, 64); err == nil {
		t.Fatal("expected error for empty identity")
	}
}

func TestDecodeIdentityRejectsBadBase64(t *testing.T) {
	if _, err := decodeIdentity("!!!not base64!!!", 8, 64); err == nil {
		t.Fatal("expected base64 error")
	}
}

func TestDecodeIdentityEnforcesLengthBounds(t *testing.T) {
	// 4 bytes of payload -> "AAECAw" (raw url, 6 chars).
	short := "AAECAw"
	if _, err := decodeIdentity(short, 8, 64); err == nil {
		t.Fatal("expected length error for short identity")
	}

	tooLongBytes := strings.Repeat("A", 200)
	if _, err := decodeIdentity(tooLongBytes, 8, 64); err == nil {
		t.Fatal("expected length error for over-cap identity")
	}
}

func TestDecodeIdentityAcceptsInRangeBytes(t *testing.T) {
	// raw url base64 of 16 bytes is 22 chars (no padding).
	good := "AAAAAAAAAAAAAAAAAAAAAA" // 16 zero bytes
	b, err := decodeIdentity(good, 8, 64)
	if err != nil {
		t.Fatalf("unexpected: %v", err)
	}
	if len(b) != 16 {
		t.Fatalf("expected 16 bytes, got %d", len(b))
	}
}

func TestDecodeCiphertextRejectsOversize(t *testing.T) {
	// 12 bytes of base64 = 9 bytes payload; cap at 8.
	if _, err := decodeCiphertext("AAAAAAAAAAAA", 8); err == nil {
		t.Fatal("expected oversize error")
	}
}

func TestClampTTL(t *testing.T) {
	s := &Server{
		cfg: config.Config{
			EnvelopeTTLMin: 24 * time.Hour,
			EnvelopeTTLMax: 168 * time.Hour,
		},
	}
	if got := s.clampTTL(0); got != 24*time.Hour {
		t.Errorf("below-min not clamped: %s", got)
	}
	if got := s.clampTTL(72 * time.Hour); got != 72*time.Hour {
		t.Errorf("in-range not preserved: %s", got)
	}
	if got := s.clampTTL(500 * time.Hour); got != 168*time.Hour {
		t.Errorf("above-max not clamped: %s", got)
	}
}

func TestClassifyEndpoint(t *testing.T) {
	cases := []struct {
		method, path, want string
	}{
		{"POST", "/v1/envelopes", "envelopes"},
		{"POST", "/v1/envelopes/abc/ack", "envelopes_ack"},
		{"GET", "/v1/inbox/xyz", "inbox"},
		{"POST", "/v1/disconnect", "disconnect"},
		{"POST", "/v1/handshake/establish", "handshake_establish"},
		{"GET", "/healthz", "healthz"},
		{"GET", "/readyz", "readyz"},
		{"GET", "/foo", "other"},
	}
	for _, c := range cases {
		t.Run(c.path, func(t *testing.T) {
			r := newRequest(c.method, c.path)
			if got := classifyEndpoint(r); got != c.want {
				t.Errorf("classifyEndpoint(%s) = %q, want %q", c.path, got, c.want)
			}
		})
	}
}

func TestStatusClass(t *testing.T) {
	cases := []struct {
		code int
		want string
	}{
		{200, "2xx"}, {204, "2xx"},
		{301, "3xx"}, {404, "4xx"},
		{500, "5xx"}, {503, "5xx"},
	}
	for _, c := range cases {
		if got := statusClass(c.code); got != c.want {
			t.Errorf("statusClass(%d) = %q, want %q", c.code, got, c.want)
		}
	}
}

func TestFirstNonNilReturnsFirstError(t *testing.T) {
	if got := firstNonNil(nil, nil, errors.New("a"), errors.New("b")); got == nil || got.Error() != "a" {
		t.Fatalf("unexpected: %v", got)
	}
	if got := firstNonNil(nil, nil); got != nil {
		t.Fatalf("expected nil for all-nil input, got %v", got)
	}
}
