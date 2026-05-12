package config

import (
	"os"
	"strings"
	"testing"
	"time"
)

func TestLoadRequiresDatabaseURL(t *testing.T) {
	t.Setenv("DATABASE_URL", "")
	_, err := Load()
	if err == nil || !strings.Contains(err.Error(), "DATABASE_URL is required") {
		t.Fatalf("expected DATABASE_URL error, got %v", err)
	}
}

func TestLoadAppliesDefaultsWhenOnlyDSNProvided(t *testing.T) {
	clearEnv(t)
	t.Setenv("DATABASE_URL", "postgres://relay@localhost/relay")

	c, err := Load()
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if c.EnvelopeMaxBytes != 65536 {
		t.Errorf("EnvelopeMaxBytes default = %d", c.EnvelopeMaxBytes)
	}
	if c.EnvelopeTTLMin != 24*time.Hour {
		t.Errorf("EnvelopeTTLMin default = %s", c.EnvelopeTTLMin)
	}
	if c.SweeperInterval != time.Minute {
		t.Errorf("SweeperInterval default = %s", c.SweeperInterval)
	}
}

func TestLoadRejectsOverlongTTLs(t *testing.T) {
	clearEnv(t)
	t.Setenv("DATABASE_URL", "postgres://relay@localhost/relay")
	t.Setenv("ENVELOPE_TTL_MAX", "2000h") // ~83 days

	_, err := Load()
	if err == nil || !strings.Contains(err.Error(), "ENVELOPE_TTL_MAX") {
		t.Fatalf("expected ENVELOPE_TTL_MAX error, got %v", err)
	}
}

func TestLoadRejectsInvertedTTLs(t *testing.T) {
	clearEnv(t)
	t.Setenv("DATABASE_URL", "postgres://relay@localhost/relay")
	t.Setenv("ENVELOPE_TTL_MIN", "48h")
	t.Setenv("ENVELOPE_TTL_MAX", "24h")

	_, err := Load()
	if err == nil || !strings.Contains(err.Error(), "ENVELOPE_TTL_MIN") {
		t.Fatalf("expected inverted-TTL error, got %v", err)
	}
}

func TestLoadRejectsOversizeEnvelopeCap(t *testing.T) {
	clearEnv(t)
	t.Setenv("DATABASE_URL", "postgres://relay@localhost/relay")
	t.Setenv("ENVELOPE_MAX_BYTES", "2097152") // 2 MiB

	_, err := Load()
	if err == nil || !strings.Contains(err.Error(), "ENVELOPE_MAX_BYTES") {
		t.Fatalf("expected ENVELOPE_MAX_BYTES error, got %v", err)
	}
}

func clearEnv(t *testing.T) {
	t.Helper()
	for _, k := range []string{
		"DATABASE_URL", "PUBLIC_LISTEN_ADDR", "PRIVATE_LISTEN_ADDR",
		"ENVELOPE_MAX_BYTES", "ENVELOPE_TTL_MIN", "ENVELOPE_TTL_MAX",
		"IDEMPOTENCY_TTL", "DISCONNECT_GRACE", "ROUTING_INACTIVITY_TTL",
		"SWEEPER_INTERVAL", "RATE_LIMIT_PER_IDENTITY", "RATE_LIMIT_PER_IP",
		"SHUTDOWN_TIMEOUT",
	} {
		if _, ok := os.LookupEnv(k); ok {
			t.Setenv(k, "")
		}
	}
}
