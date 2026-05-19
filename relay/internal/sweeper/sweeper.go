// Package sweeper is the periodic task that enforces the relay's
// retention semantics: undelivered envelopes are deleted at TTL,
// idempotency entries are deleted at TTL, disconnecting routing rows
// are deleted after the grace window, and inactive routing rows are
// deleted after the long-inactivity TTL.
//
// Every run records a checkpoint and emits per-counter metrics so a
// stuck sweeper surfaces in the dashboards
// (`relay-state-schema-and-retention` /
// "Undelivered envelopes are deleted at TTL expiry").
package sweeper

import (
	"context"
	"time"

	"github.com/compartarenta/relay/internal/config"
	"github.com/compartarenta/relay/internal/logging"
	"github.com/compartarenta/relay/internal/metrics"
	"github.com/compartarenta/relay/internal/store"
)

// Sweeper holds the dependencies a single sweep needs.
type Sweeper struct {
	cfg    config.Config
	store  *store.Store
	logger *logging.Logger
	now    func() time.Time
}

// New builds a Sweeper.
func New(cfg config.Config, st *store.Store, l *logging.Logger) *Sweeper {
	return &Sweeper{cfg: cfg, store: st, logger: l, now: time.Now}
}

// SetClock replaces the wall-clock source. Tests only.
func (s *Sweeper) SetClock(now func() time.Time) { s.now = now }

// Run executes one sweep and returns the per-category counts. Errors
// during sub-deletions are aggregated but do not abort the remaining
// passes — the sweeper is best-effort and re-runs on schedule.
func (s *Sweeper) Run(ctx context.Context) (Stats, error) {
	start := s.now()
	timer := metrics.SweeperRunDuration

	envExpired, errEnv := s.store.SweepEnvelopes(ctx, start)
	idemExpired, errIdem := s.store.SweepIdempotency(ctx, start)
	routingPruned, errRoute := s.store.PruneExpiredRouting(ctx,
		start, s.cfg.DisconnectGrace, s.cfg.RoutingInactivityTTL)
	pushPurged, errPush := s.store.PurgeExpiredRoutingPushTokens(ctx, start)

	if errEnv == nil {
		metrics.EnvelopesExpired.Add(float64(envExpired))
	}
	if errIdem == nil {
		metrics.IdempotencyExpired.Add(float64(idemExpired))
	}
	if errRoute == nil {
		metrics.RoutingSevered.Add(float64(routingPruned))
	}
	if errPush == nil && pushPurged > 0 {
		dayUTC := time.Date(start.UTC().Year(), start.UTC().Month(), start.UTC().Day(), 0, 0, 0, 0, time.UTC)
		if err := s.store.MergeDayMetrics(ctx, dayUTC, 0, 0, pushPurged); err != nil {
			errPush = err
		}
	}
	metrics.SweeperRuns.Inc()
	timer.Observe(time.Since(start).Seconds())

	cpErr := s.store.RecordCheckpoint(ctx, start, envExpired, idemExpired, routingPruned)

	if depth, err := s.store.QueueDepth(ctx); err == nil {
		metrics.QueueDepth.Set(float64(depth))
	}
	if age, err := s.store.OldestUndeliveredAge(ctx, start); err == nil {
		metrics.OldestUndeliveredSeconds.Set(age.Seconds())
	}

	stats := Stats{
		At:                 start,
		EnvelopesExpired:   envExpired,
		IdempotencyExpired: idemExpired,
		RoutingPruned:      routingPruned,
	}
	s.logger.Info(ctx, "sweeper.run",
		logging.F(logging.KeyComponent, "sweeper"),
		logging.F(logging.KeyCountEnvExp, envExpired),
		logging.F(logging.KeyCountIdemExp, idemExpired),
		logging.F(logging.KeyCountRoutPrune, routingPruned),
		logging.F(logging.KeyDurationMS, time.Since(start).Milliseconds()),
	)

	return stats, firstNonNil(errEnv, errIdem, errRoute, errPush, cpErr)
}

// Loop runs `Run` on `cfg.SweeperInterval` until ctx is cancelled.
func (s *Sweeper) Loop(ctx context.Context) {
	t := time.NewTicker(s.cfg.SweeperInterval)
	defer t.Stop()
	for {
		select {
		case <-ctx.Done():
			return
		case <-t.C:
			if _, err := s.Run(ctx); err != nil {
				s.logger.Warn(ctx, "sweeper.run_error",
					logging.F(logging.KeyComponent, "sweeper"),
					logging.F(logging.KeyError, err.Error()),
				)
			}
		}
	}
}

// Stats is the result of a single sweep.
type Stats struct {
	At                 time.Time
	EnvelopesExpired   int64
	IdempotencyExpired int64
	RoutingPruned      int64
}

func firstNonNil(errs ...error) error {
	for _, err := range errs {
		if err != nil {
			return err
		}
	}
	return nil
}
