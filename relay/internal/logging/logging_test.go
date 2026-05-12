package logging

import (
	"bytes"
	"context"
	"encoding/json"
	"log/slog"
	"testing"
)

func TestAllowListDropsForbiddenFields(t *testing.T) {
	var buf bytes.Buffer
	h := slog.NewJSONHandler(&buf, &slog.HandlerOptions{Level: slog.LevelInfo})
	l := &Logger{base: slog.New(h)}

	l.Info(context.Background(), "test",
		F(KeyEndpoint, "envelopes"),
		F("ciphertext", "this-should-be-dropped"),
		F("display_name", "Alice"),
		F("email", "alice@example.com"),
		F(KeyEnvelopeID, "deadbeef"),
	)

	var entry map[string]any
	if err := json.Unmarshal(buf.Bytes(), &entry); err != nil {
		t.Fatalf("invalid JSON: %v\n%s", err, buf.String())
	}
	if _, leaked := entry["ciphertext"]; leaked {
		t.Errorf("forbidden field 'ciphertext' must not appear: %s", buf.String())
	}
	if _, leaked := entry["display_name"]; leaked {
		t.Errorf("forbidden field 'display_name' must not appear: %s", buf.String())
	}
	if _, leaked := entry["email"]; leaked {
		t.Errorf("forbidden field 'email' must not appear: %s", buf.String())
	}
	if _, present := entry["endpoint"]; !present {
		t.Errorf("allow-listed field 'endpoint' must appear: %s", buf.String())
	}
	if _, present := entry["envelope_id"]; !present {
		t.Errorf("allow-listed field 'envelope_id' must appear: %s", buf.String())
	}
}

func TestBytesEncodesAsHex(t *testing.T) {
	f := Bytes(KeyEnvelopeID, []byte{0xde, 0xad, 0xbe, 0xef})
	if f.Value != "deadbeef" {
		t.Errorf("expected hex 'deadbeef', got %q", f.Value)
	}
}
