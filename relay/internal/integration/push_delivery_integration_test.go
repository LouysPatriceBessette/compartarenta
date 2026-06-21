//go:build integration

package integration

import (
	"bytes"
	"context"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"testing"
	"time"

	"golang.org/x/oauth2"

	"github.com/compartarenta/relay/internal/api"
	"github.com/compartarenta/relay/internal/logging"
	"github.com/compartarenta/relay/internal/push"
	"github.com/compartarenta/relay/internal/stats"
	"github.com/compartarenta/relay/internal/store"
	"github.com/compartarenta/relay/internal/sweeper"
)

func TestIntegrationPurgeExpiredRoutingPushTokens(t *testing.T) {
	ctx := context.Background()
	dsn := integrationDSN(t)
	st, err := store.New(ctx, dsn)
	if err != nil {
		t.Fatalf("store.New: %v", err)
	}
	t.Cleanup(func() { st.Close() })
	resetRelayData(ctx, t, dsn)

	recipient := mustDecodeB64ID(t, b64ID(0x41, 8))
	now := time.Date(2026, 6, 21, 12, 0, 0, 0, time.UTC)
	expired := now.Add(-time.Hour)
	active := now.Add(24 * time.Hour)

	if err := st.UpsertRoutingPushToken(ctx, recipient, "fcm", "expired-token", "UNDISCLOSED", expired, now.Add(-48*time.Hour), now.Add(-48*time.Hour)); err != nil {
		t.Fatalf("insert expired: %v", err)
	}
	if err := st.UpsertRoutingPushToken(ctx, recipient, "fcm", "active-token", "CA", active, now, now); err != nil {
		t.Fatalf("insert active: %v", err)
	}

	n, err := st.PurgeExpiredRoutingPushTokens(ctx, now)
	if err != nil {
		t.Fatalf("purge: %v", err)
	}
	if n != 1 {
		t.Fatalf("purged %d want 1", n)
	}

	rows, err := st.ListRoutingPushTokensForRecipient(ctx, recipient, now)
	if err != nil {
		t.Fatalf("list: %v", err)
	}
	if len(rows) != 1 || rows[0].PushToken != "active-token" {
		t.Fatalf("active row missing: %+v", rows)
	}
}

func TestIntegrationSweeperPurgesPushTokensAndMetrics(t *testing.T) {
	ctx := context.Background()
	dsn := integrationDSN(t)
	st, err := store.New(ctx, dsn)
	if err != nil {
		t.Fatalf("store.New: %v", err)
	}
	t.Cleanup(func() { st.Close() })
	resetRelayData(ctx, t, dsn)

	sweepAt := time.Date(2026, 6, 21, 12, 0, 0, 0, time.UTC)
	recipient := mustDecodeB64ID(t, b64ID(0x42, 8))
	if err := st.UpsertRoutingPushToken(ctx, recipient, "fcm", "gone", "UNDISCLOSED", sweepAt.Add(-time.Minute), sweepAt.Add(-48*time.Hour), sweepAt.Add(-48*time.Hour)); err != nil {
		t.Fatalf("insert: %v", err)
	}

	cfg := testConfig(dsn)
	sw := sweeper.New(cfg, st, logging.NewForTest())
	sw.SetClock(func() time.Time { return sweepAt })
	if _, err := sw.Run(ctx); err != nil {
		t.Fatalf("sweep: %v", err)
	}

	m, err := st.GetDayMetrics(ctx, sweepAt)
	if err != nil {
		t.Fatalf("metrics: %v", err)
	}
	if m.RoutingPushTokenPurges != 1 {
		t.Fatalf("purge metric %d want 1", m.RoutingPushTokenPurges)
	}
}

func TestIntegrationWakeDispatchFanOutAndPermanentPurge(t *testing.T) {
	ctx := context.Background()
	dsn := integrationDSN(t)
	st, err := store.New(ctx, dsn)
	if err != nil {
		t.Fatalf("store.New: %v", err)
	}
	t.Cleanup(func() { st.Close() })
	resetRelayData(ctx, t, dsn)

	recipient := mustDecodeB64ID(t, b64ID(0x43, 8))
	now := time.Date(2026, 6, 21, 15, 0, 0, 0, time.UTC)
	expires := now.Add(14 * 24 * time.Hour)

	var sendCount int
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		sendCount++
		if sendCount == 1 {
			http.Error(w, `{"error":"not_registered"}`, http.StatusBadRequest)
			return
		}
		w.WriteHeader(http.StatusOK)
		_, _ = w.Write([]byte(`{"name":"ok"}`))
	}))
	t.Cleanup(srv.Close)

	if err := st.UpsertRoutingPushToken(ctx, recipient, "fcm", "bad-token", "UNDISCLOSED", expires, now, now); err != nil {
		t.Fatalf("bad token: %v", err)
	}
	if err := st.UpsertRoutingPushToken(ctx, recipient, "fcm", "good-token", "UNDISCLOSED", expires, now, now); err != nil {
		t.Fatalf("good token: %v", err)
	}

	fcm := &push.FCMDataWake{
		HTTPClient: srv.Client(),
		ProjectID:  "test-project",
		TokenSrc:   oauth2.StaticTokenSource(&oauth2.Token{AccessToken: "test", Expiry: now.Add(time.Hour)}),
		APIBaseURL: srv.URL,
	}
	disp := push.NewDispatcher(st, logging.NewForTest(), fcm, nil)
	disp.SetClock(func() time.Time { return now })
	disp.WakeRecipient(ctx, recipient)

	if sendCount != 2 {
		t.Fatalf("sendCount %d want 2", sendCount)
	}

	rows, err := st.ListRoutingPushTokensForRecipient(ctx, recipient, now)
	if err != nil {
		t.Fatalf("list: %v", err)
	}
	if len(rows) != 1 || rows[0].PushToken != "good-token" {
		t.Fatalf("bad token not purged: %+v", rows)
	}

	m, err := st.GetDayMetrics(ctx, now)
	if err != nil {
		t.Fatalf("metrics: %v", err)
	}
	if m.DispatchSuccess != 1 || m.DispatchFailure != 1 {
		t.Fatalf("dispatch metrics success=%d failure=%d", m.DispatchSuccess, m.DispatchFailure)
	}
}

func TestIntegrationEnvelopeAcceptedTriggersWakeDispatch(t *testing.T) {
	ctx := context.Background()
	dsn := integrationDSN(t)
	st, err := store.New(ctx, dsn)
	if err != nil {
		t.Fatalf("store.New: %v", err)
	}
	t.Cleanup(func() { st.Close() })
	resetRelayData(ctx, t, dsn)

	sender := mustDecodeB64ID(t, b64ID(0x50, 8))
	recipient := mustDecodeB64ID(t, b64ID(0x51, 8))
	if err := st.EstablishRouting(ctx, sender, recipient); err != nil {
		t.Fatalf("routing: %v", err)
	}

	now := time.Now().UTC()
	expires := now.Add(14 * 24 * time.Hour)
	if err := st.UpsertRoutingPushToken(ctx, recipient, "fcm", "wake-me", "UNDISCLOSED", expires, now, now); err != nil {
		t.Fatalf("register token: %v", err)
	}

	var woke int
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		woke++
		w.WriteHeader(http.StatusOK)
		_, _ = w.Write([]byte(`{"name":"projects/x/messages/1"}`))
	}))
	t.Cleanup(srv.Close)

	fcm := &push.FCMDataWake{
		HTTPClient: srv.Client(),
		ProjectID:  "proj",
		TokenSrc:   oauth2.StaticTokenSource(&oauth2.Token{AccessToken: "t", Expiry: now.Add(time.Hour)}),
		APIBaseURL: srv.URL,
	}
	disp := push.NewDispatcher(st, logging.NewForTest(), fcm, nil)

	cfg := testConfig(dsn)
	cfg.WakePushDispatchEnabled = true
	srvAPI := api.NewServer(cfg, st, logging.NewForTest(), disp)
	h := srvAPI.PublicHandler()

	body := map[string]any{
		"sender_identity":    b64ID(0x50, 8),
		"recipient_identity": b64ID(0x51, 8),
		"idempotency_key":    b64ID(0x52, 8),
		"ciphertext":         "AQID",
		"kind":               1,
		"ttl_seconds":        3600,
	}
	payload, _ := json.Marshal(body)
	req := httptest.NewRequest(http.MethodPost, "/v1/envelopes", bytes.NewReader(payload))
	req.Header.Set("Content-Type", "application/json")
	rr := httptest.NewRecorder()
	h.ServeHTTP(rr, req)
	if rr.Code != http.StatusCreated {
		t.Fatalf("envelope status %d body %s", rr.Code, rr.Body.String())
	}

	deadline := time.Now().Add(3 * time.Second)
	for woke == 0 && time.Now().Before(deadline) {
		time.Sleep(10 * time.Millisecond)
	}
	if woke != 1 {
		t.Fatalf("wake dispatch count %d want 1", woke)
	}
}

func TestIntegrationDailyStatsEndpointAggregates(t *testing.T) {
	ctx := context.Background()
	dsn := integrationDSN(t)
	st, err := store.New(ctx, dsn)
	if err != nil {
		t.Fatalf("store.New: %v", err)
	}
	t.Cleanup(func() { st.Close() })
	resetRelayData(ctx, t, dsn)

	day := time.Date(2026, 6, 20, 0, 0, 0, 0, time.UTC)
	seen := day.Add(10 * time.Hour)
	recipient := mustDecodeB64ID(t, b64ID(0x60, 8))
	expires := seen.Add(14 * 24 * time.Hour)
	if err := st.UpsertRoutingPushToken(ctx, recipient, "fcm", "t1", "CA", expires, seen, seen); err != nil {
		t.Fatalf("insert: %v", err)
	}
	if err := st.MergeDayMetrics(ctx, day, 2, 1, 3); err != nil {
		t.Fatalf("metrics: %v", err)
	}

	rep, err := stats.BuildDailyReport(ctx, st, day)
	if err != nil {
		t.Fatalf("report: %v", err)
	}
	if rep.ActiveTotal != 1 {
		t.Fatalf("active_total %d want 1", rep.ActiveTotal)
	}
	if rep.ByCountry["CA"] != 1 {
		t.Fatalf("by_country CA %v", rep.ByCountry)
	}
	if rep.DispatchSuccessCount != 2 || rep.DispatchFailureCount != 1 || rep.PurgeCount != 3 {
		t.Fatalf("metrics %+v", rep)
	}
}

func TestDailyStatsAppendScriptIdempotent(t *testing.T) {
	repoRoot := filepath.Clean(filepath.Join("..", "..", ".."))
	script := filepath.Join(repoRoot, "scripts", "daily-stats-append.sh")
	if _, err := os.Stat(script); err != nil {
		t.Fatalf("script: %v", err)
	}

	yesterdayRaw, err := exec.Command("bash", "-c", `date -u -d yesterday +%F 2>/dev/null || date -u -v-1d +%F`).Output()
	if err != nil {
		t.Fatalf("yesterday date: %v", err)
	}
	yesterday := strings.TrimSpace(string(yesterdayRaw))

	statsSrv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if !strings.Contains(r.URL.RawQuery, yesterday) {
			http.Error(w, "wrong date", http.StatusBadRequest)
			return
		}
		_ = json.NewEncoder(w).Encode(map[string]any{"date": yesterday, "active_total": 1})
	}))
	t.Cleanup(statsSrv.Close)

	dir := t.TempDir()
	statsFile := filepath.Join(dir, "daily.jsonl")
	line := `{"date":"` + yesterday + `","active_total":1}` + "\n"
	if err := os.WriteFile(statsFile, []byte(line), 0o644); err != nil {
		t.Fatalf("write stats: %v", err)
	}

	cmd := exec.Command("bash", script)
	cmd.Env = append(os.Environ(),
		"RELAY_STATS_URL="+statsSrv.URL,
		"STATS_FILE_PATH="+statsFile,
	)
	out, err := cmd.CombinedOutput()
	if err != nil {
		t.Fatalf("script: %v output %s", err, out)
	}
	data, err := os.ReadFile(statsFile)
	if err != nil {
		t.Fatalf("read stats: %v", err)
	}
	if strings.Count(string(data), `"date":"`+yesterday+`"`) != 1 {
		t.Fatalf("expected single line for %s, got:\n%s", yesterday, data)
	}
}
