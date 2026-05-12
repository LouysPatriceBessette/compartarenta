// Package config loads the relay's runtime configuration from environment
// variables. Secrets are never embedded in source or in the container
// image; they are sourced at runtime from an explicit secret store
// (`relay-security-baseline` / "Secrets are managed by an explicit secret
// store"). This package therefore never defaults a secret to a non-empty
// value.
package config

import (
	"errors"
	"fmt"
	"os"
	"strconv"
	"strings"
	"time"
)

// Config is the relay's loaded configuration.
type Config struct {
	// PublicListenAddr is the address:port the relay protocol binds to.
	// The reverse proxy in front of the relay terminates TLS and forwards
	// here on a private network. Default: 0.0.0.0:8080.
	PublicListenAddr string

	// PrivateListenAddr serves /metrics and any future inspection
	// endpoints. MUST be bound to a private network only; the deployment
	// manifest does not publish this port to the public internet
	// (`relay-observability-without-plaintext` / "The metrics endpoint is
	// not publicly reachable"). Default: 127.0.0.1:9090.
	PrivateListenAddr string

	// DatabaseURL is the libpq-style DSN for the PostgreSQL instance.
	// Required; no default. Loaded from the env at runtime.
	DatabaseURL string

	// EnvelopeMaxBytes caps the ciphertext size of a single envelope.
	// Oversize requests are rejected before any state is written
	// (`relay-security-baseline` / "The relay applies a documented size
	// limit per envelope"). Default: 65536 bytes (64 KiB).
	EnvelopeMaxBytes int

	// EnvelopeTTLMin/Max bound the per-envelope TTL value chosen by the
	// API layer. The relay clamps client-requested TTLs into this range
	// (`relay-state-schema-and-retention` / "TTL values fall within
	// documented bounds and are publicly stated"). Defaults: 24h / 168h
	// (7 days).
	EnvelopeTTLMin time.Duration
	EnvelopeTTLMax time.Duration

	// IdempotencyTTL is the lifetime of an idempotency entry. Hours, not
	// weeks. Default: 24h.
	IdempotencyTTL time.Duration

	// DisconnectGrace is how long a relationship row stays in the
	// `disconnecting` state to allow in-flight envelopes to flush before
	// the row is deleted. Default: 5 minutes.
	DisconnectGrace time.Duration

	// RoutingInactivityTTL is the long-inactivity window after which a
	// routing relationship is pruned. The minimum window is set by the
	// spec; the operator picks a concrete value at or above the minimum.
	// Default: 26 weeks (~6 months).
	RoutingInactivityTTL time.Duration

	// SweeperInterval is how often the sweeper task runs. Default: 1m.
	SweeperInterval time.Duration

	// RateLimitPerIdentity is the per-opaque-identity submission rate.
	// Token bucket of size 4*Rate, refill at Rate tokens/sec. Default: 5.
	RateLimitPerIdentity float64

	// RateLimitPerIP is the per-source-IP submission rate. Default: 20.
	RateLimitPerIP float64

	// ShutdownTimeout caps the time the relay waits for in-flight
	// requests to complete on SIGTERM/SIGINT. Default: 30s.
	ShutdownTimeout time.Duration
}

// Load reads configuration from environment variables. Errors are
// aggregated so the operator sees every problem at once.
func Load() (Config, error) {
	var errs []error
	c := Config{
		PublicListenAddr:     env("PUBLIC_LISTEN_ADDR", "0.0.0.0:8080"),
		PrivateListenAddr:    env("PRIVATE_LISTEN_ADDR", "127.0.0.1:9090"),
		DatabaseURL:          os.Getenv("DATABASE_URL"),
		EnvelopeMaxBytes:     intEnv(&errs, "ENVELOPE_MAX_BYTES", 65536),
		EnvelopeTTLMin:       durEnv(&errs, "ENVELOPE_TTL_MIN", 24*time.Hour),
		EnvelopeTTLMax:       durEnv(&errs, "ENVELOPE_TTL_MAX", 168*time.Hour),
		IdempotencyTTL:       durEnv(&errs, "IDEMPOTENCY_TTL", 24*time.Hour),
		DisconnectGrace:      durEnv(&errs, "DISCONNECT_GRACE", 5*time.Minute),
		RoutingInactivityTTL: durEnv(&errs, "ROUTING_INACTIVITY_TTL", 26*7*24*time.Hour),
		SweeperInterval:      durEnv(&errs, "SWEEPER_INTERVAL", time.Minute),
		RateLimitPerIdentity: floatEnv(&errs, "RATE_LIMIT_PER_IDENTITY", 5),
		RateLimitPerIP:       floatEnv(&errs, "RATE_LIMIT_PER_IP", 20),
		ShutdownTimeout:      durEnv(&errs, "SHUTDOWN_TIMEOUT", 30*time.Second),
	}
	if c.DatabaseURL == "" {
		errs = append(errs, errors.New("DATABASE_URL is required and must come from an explicit secret store (not committed)"))
	}
	if c.EnvelopeTTLMin <= 0 || c.EnvelopeTTLMax <= 0 || c.EnvelopeTTLMin > c.EnvelopeTTLMax {
		errs = append(errs, fmt.Errorf("ENVELOPE_TTL_MIN (%s) and ENVELOPE_TTL_MAX (%s) must be > 0 and MIN <= MAX",
			c.EnvelopeTTLMin, c.EnvelopeTTLMax))
	}
	if c.EnvelopeTTLMax > 30*24*time.Hour {
		errs = append(errs, fmt.Errorf("ENVELOPE_TTL_MAX (%s) exceeds the spec's conservative ceiling (~30 days); reduce it",
			c.EnvelopeTTLMax))
	}
	if c.IdempotencyTTL > 7*24*time.Hour {
		errs = append(errs, fmt.Errorf("IDEMPOTENCY_TTL (%s) exceeds the spec's conservative ceiling (~7 days); reduce it",
			c.IdempotencyTTL))
	}
	if c.EnvelopeMaxBytes <= 0 || c.EnvelopeMaxBytes > 1<<20 {
		errs = append(errs, fmt.Errorf("ENVELOPE_MAX_BYTES (%d) must be in (0, 1 MiB]", c.EnvelopeMaxBytes))
	}
	if len(errs) > 0 {
		return c, errors.Join(errs...)
	}
	return c, nil
}

func env(key, def string) string {
	if v, ok := os.LookupEnv(key); ok && strings.TrimSpace(v) != "" {
		return v
	}
	return def
}

func intEnv(errs *[]error, key string, def int) int {
	raw, ok := os.LookupEnv(key)
	if !ok || strings.TrimSpace(raw) == "" {
		return def
	}
	n, err := strconv.Atoi(strings.TrimSpace(raw))
	if err != nil {
		*errs = append(*errs, fmt.Errorf("%s: invalid integer: %w", key, err))
		return def
	}
	return n
}

func floatEnv(errs *[]error, key string, def float64) float64 {
	raw, ok := os.LookupEnv(key)
	if !ok || strings.TrimSpace(raw) == "" {
		return def
	}
	v, err := strconv.ParseFloat(strings.TrimSpace(raw), 64)
	if err != nil {
		*errs = append(*errs, fmt.Errorf("%s: invalid float: %w", key, err))
		return def
	}
	return v
}

func durEnv(errs *[]error, key string, def time.Duration) time.Duration {
	raw, ok := os.LookupEnv(key)
	if !ok || strings.TrimSpace(raw) == "" {
		return def
	}
	d, err := time.ParseDuration(strings.TrimSpace(raw))
	if err != nil {
		*errs = append(*errs, fmt.Errorf("%s: invalid duration: %w", key, err))
		return def
	}
	return d
}
