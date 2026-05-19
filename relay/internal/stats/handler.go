package stats

import (
	"context"
	"encoding/json"
	"net"
	"net/http"
	"time"

	"github.com/compartarenta/relay/internal/store"
)

// CountrySuppressionThreshold is the minimum per-country daily active count
// before a country bucket is merged into OTHER. Hard-coded per product spec
// (not configurable via environment).
const CountrySuppressionThreshold = 10

// IsLoopbackRemote reports whether the request arrived from a loopback address.
func IsLoopbackRemote(r *http.Request) bool {
	host, _, err := net.SplitHostPort(r.RemoteAddr)
	if err != nil {
		host = r.RemoteAddr
	}
	ip := net.ParseIP(host)
	return ip != nil && ip.IsLoopback()
}

// DailyReport is the JSON shape returned by GET /internal/stats/daily and
// written as one line per day by the operator cron job.
type DailyReport struct {
	Date                       string         `json:"date"`
	ActiveTotal                int64          `json:"active_total"`
	ByCountry                  map[string]int64 `json:"by_country"`
	ByProvider                 map[string]int64 `json:"by_provider"`
	DispatchSuccessCount       int64          `json:"dispatch_success_count"`
	DispatchFailureCount       int64          `json:"dispatch_failure_count"`
	PurgeCount                 int64          `json:"purge_count"`
	RoutingPushTokensRowCount  int64          `json:"routing_push_tokens_row_count"`
}

func utcDayBounds(day time.Time) (start, end time.Time) {
	d := time.Date(day.Year(), day.Month(), day.Day(), 0, 0, 0, 0, time.UTC)
	return d, d.Add(24 * time.Hour)
}

// SuppressSmallCountryBuckets merges per-country counts below
// [CountrySuppressionThreshold] into OTHER. UNDISCLOSED is never merged.
func SuppressSmallCountryBuckets(by map[string]int64) map[string]int64 {
	out := make(map[string]int64)
	var other int64
	for k, v := range by {
		if k == "UNDISCLOSED" {
			out[k] += v
			continue
		}
		if v < CountrySuppressionThreshold {
			other += v
		} else {
			out[k] += v
		}
	}
	if other > 0 {
		out["OTHER"] += other
	}
	return out
}

// BuildDailyReport aggregates store state for a UTC calendar day.
func BuildDailyReport(ctx context.Context, st *store.Store, dayUTC time.Time) (DailyReport, error) {
	start, end := utcDayBounds(dayUTC)
	snap, err := st.DailyActiveSnapshotForRange(ctx, start, end)
	if err != nil {
		return DailyReport{}, err
	}
	metrics, err := st.GetDayMetrics(ctx, dayUTC)
	if err != nil {
		return DailyReport{}, err
	}
	rowCount, err := st.CountRoutingPushTokens(ctx)
	if err != nil {
		return DailyReport{}, err
	}
	byCountry := SuppressSmallCountryBuckets(snap.ByCountry)
	byProv := snap.ByProvider
	if byProv == nil {
		byProv = map[string]int64{}
	}
	if _, ok := byProv["fcm"]; !ok {
		byProv["fcm"] = 0
	}
	if _, ok := byProv["apns"]; !ok {
		byProv["apns"] = 0
	}
	return DailyReport{
		Date:                      dayUTC.Format("2006-01-02"),
		ActiveTotal:               snap.ActiveTotal,
		ByCountry:                 byCountry,
		ByProvider:                byProv,
		DispatchSuccessCount:      metrics.DispatchSuccess,
		DispatchFailureCount:      metrics.DispatchFailure,
		PurgeCount:                metrics.RoutingPushTokenPurges,
		RoutingPushTokensRowCount: rowCount,
	}, nil
}

// Handler returns an http.Handler for GET /internal/stats/daily.
func Handler(st *store.Store, now func() time.Time) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if r.Method != http.MethodGet {
			http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
			return
		}
		if !IsLoopbackRemote(r) {
			http.NotFound(w, r)
			return
		}
		q := r.URL.Query().Get("date")
		var day time.Time
		if q == "" {
			t := now().UTC().AddDate(0, 0, -1)
			day = time.Date(t.Year(), t.Month(), t.Day(), 0, 0, 0, 0, time.UTC)
		} else {
			parsed, err := time.ParseInLocation("2006-01-02", q, time.UTC)
			if err != nil {
				http.Error(w, "invalid date", http.StatusBadRequest)
				return
			}
			day = parsed
		}
		rep, err := BuildDailyReport(r.Context(), st, day)
		if err != nil {
			http.Error(w, "internal", http.StatusInternalServerError)
			return
		}
		w.Header().Set("Content-Type", "application/json")
		_ = json.NewEncoder(w).Encode(rep)
	})
}
