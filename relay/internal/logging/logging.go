// Package logging provides a thin wrapper over `log/slog` that enforces
// an explicit field allow-list. The relay logs operational metadata
// (envelope IDs, opaque identifiers, timing, status codes) and NEVER
// logs ciphertext, recipient mapping payloads, or any user-presented
// identity attribute (`relay-observability-without-plaintext` /
// "Logs do not contain user-content plaintext").
package logging

import (
	"context"
	"encoding/hex"
	"log/slog"
	"os"
)

// FieldKey is a typed key for log attributes. New keys MUST be added to
// `allowedKeys` below; the wrapper drops anything else at write time so
// an accidental call site cannot leak a forbidden field.
type FieldKey string

const (
	KeyEndpoint        FieldKey = "endpoint"
	KeyMethod          FieldKey = "method"
	KeyStatus          FieldKey = "status"
	KeyEnvelopeID      FieldKey = "envelope_id"
	KeySenderIdentity  FieldKey = "sender_identity"
	KeyRecipientIdent  FieldKey = "recipient_identity"
	KeyError           FieldKey = "error"
	KeyDurationMS      FieldKey = "duration_ms"
	KeyRejectionReason FieldKey = "rejection_reason"
	KeySchemaVersion   FieldKey = "schema_version"
	KeyMigrationCount  FieldKey = "migration_count"
	KeySweeperRun      FieldKey = "sweeper_run"
	KeyCountEnvExp     FieldKey = "envelopes_expired"
	KeyCountIdemExp    FieldKey = "idempotency_expired"
	KeyCountRoutPrune  FieldKey = "routing_pruned"
	KeyActor           FieldKey = "actor"
	KeyAction          FieldKey = "action"
	KeyTarget          FieldKey = "target"
	KeyBuild           FieldKey = "build"
	KeyAddr            FieldKey = "addr"
	KeyComponent       FieldKey = "component"
)

var allowedKeys = map[FieldKey]struct{}{
	KeyEndpoint: {}, KeyMethod: {}, KeyStatus: {}, KeyEnvelopeID: {},
	KeySenderIdentity: {}, KeyRecipientIdent: {}, KeyError: {},
	KeyDurationMS: {}, KeyRejectionReason: {}, KeySchemaVersion: {},
	KeyMigrationCount: {}, KeySweeperRun: {}, KeyCountEnvExp: {},
	KeyCountIdemExp: {}, KeyCountRoutPrune: {}, KeyActor: {},
	KeyAction: {}, KeyTarget: {}, KeyBuild: {}, KeyAddr: {},
	KeyComponent: {},
}

// Logger is the relay's allow-listed structured logger.
type Logger struct {
	base *slog.Logger
}

// New builds a Logger that emits JSON to stdout.
func New() *Logger {
	h := slog.NewJSONHandler(os.Stdout, &slog.HandlerOptions{
		Level: slog.LevelInfo,
	})
	return &Logger{base: slog.New(h)}
}

// NewForTest builds a Logger that writes to /dev/null. Used by tests that
// exercise log-emitting code paths without polluting test output.
func NewForTest() *Logger {
	h := slog.NewJSONHandler(devNull{}, &slog.HandlerOptions{
		Level: slog.LevelInfo,
	})
	return &Logger{base: slog.New(h)}
}

// Info emits an info-level entry. Forbidden fields are dropped silently.
func (l *Logger) Info(ctx context.Context, msg string, kv ...Field) {
	l.log(ctx, slog.LevelInfo, msg, kv)
}

// Warn emits a warn-level entry.
func (l *Logger) Warn(ctx context.Context, msg string, kv ...Field) {
	l.log(ctx, slog.LevelWarn, msg, kv)
}

// Error emits an error-level entry.
func (l *Logger) Error(ctx context.Context, msg string, kv ...Field) {
	l.log(ctx, slog.LevelError, msg, kv)
}

func (l *Logger) log(ctx context.Context, lvl slog.Level, msg string, kv []Field) {
	attrs := make([]slog.Attr, 0, len(kv))
	for _, f := range kv {
		if _, ok := allowedKeys[f.Key]; !ok {
			continue
		}
		attrs = append(attrs, slog.Any(string(f.Key), f.Value))
	}
	l.base.LogAttrs(ctx, lvl, msg, attrs...)
}

// Field is one structured key/value pair.
type Field struct {
	Key   FieldKey
	Value any
}

// F builds a generic field.
func F(k FieldKey, v any) Field { return Field{Key: k, Value: v} }

// Bytes returns a hex-encoded representation of the opaque identifier.
// The relay logs identifiers as hex so they can be correlated across log
// lines without revealing anything that depends on a specific binary
// representation choice.
func Bytes(k FieldKey, b []byte) Field {
	return Field{Key: k, Value: hex.EncodeToString(b)}
}

type devNull struct{}

func (devNull) Write(p []byte) (int, error) { return len(p), nil }
