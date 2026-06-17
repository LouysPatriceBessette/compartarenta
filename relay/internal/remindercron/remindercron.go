// Package remindercron dispatches due scheduled notification fires.
package remindercron

import (
	"context"
	"time"

	"github.com/compartarenta/relay/internal/config"
	"github.com/compartarenta/relay/internal/logging"
	"github.com/compartarenta/relay/internal/metrics"
	"github.com/compartarenta/relay/internal/push"
	"github.com/compartarenta/relay/internal/store"
)

const claimBatchSize = 64

// Cron holds dependencies for one reminder dispatch pass.
type Cron struct {
	cfg    config.Config
	store  *store.Store
	logger *logging.Logger
	wake   *push.Dispatcher
	now    func() time.Time
}

// New builds a Cron.
func New(cfg config.Config, st *store.Store, l *logging.Logger, wake *push.Dispatcher) *Cron {
	return &Cron{cfg: cfg, store: st, logger: l, wake: wake, now: time.Now}
}

// SetClock replaces the wall-clock source. Tests only.
func (c *Cron) SetClock(now func() time.Time) { c.now = now }

// Run claims due fires, marks them fired, and dispatches wake pushes.
func (c *Cron) Run(ctx context.Context) (int, error) {
	if !c.cfg.ReminderCronEnabled {
		return 0, nil
	}
	start := c.now()
	timer := metrics.ReminderCronRunDuration

	claimed, err := c.store.ClaimDueReminderFires(ctx, start, claimBatchSize)
	if err != nil {
		return 0, err
	}

	wake := c.wake != nil && c.cfg.WakePushDispatchEnabled
	seen := make(map[string]struct{})
	for _, d := range claimed {
		metrics.ReminderFiresDispatched.Inc()
		if !wake {
			continue
		}
		key := string(d.RecipientRoutingID)
		if _, ok := seen[key]; ok {
			continue
		}
		seen[key] = struct{}{}
		recipient := append([]byte(nil), d.RecipientRoutingID...)
		go c.wake.WakeRecipient(context.Background(), recipient)
	}

	metrics.ReminderCronRuns.Inc()
	timer.Observe(time.Since(start).Seconds())
	if len(claimed) > 0 {
		c.logger.Info(ctx, "reminder_cron.run",
			logging.F(logging.KeyComponent, "reminder_cron"),
			logging.F(logging.KeyReminderFires, len(claimed)),
			logging.F(logging.KeyDurationMS, time.Since(start).Milliseconds()),
		)
	}
	return len(claimed), nil
}

// Loop runs Run on ReminderCronInterval until ctx is cancelled.
func (c *Cron) Loop(ctx context.Context) {
	if !c.cfg.ReminderCronEnabled {
		return
	}
	t := time.NewTicker(c.cfg.ReminderCronInterval)
	defer t.Stop()
	for {
		select {
		case <-ctx.Done():
			return
		case <-t.C:
			if _, err := c.Run(ctx); err != nil {
				c.logger.Warn(ctx, "reminder_cron.run_error",
					logging.F(logging.KeyComponent, "reminder_cron"),
					logging.F(logging.KeyError, err.Error()),
				)
			}
		}
	}
}
