package push

import (
	"context"
	"errors"
	"time"

	"github.com/compartarenta/relay/internal/logging"
	"github.com/compartarenta/relay/internal/store"
)

// Dispatcher fans out wake pushes to registered device tokens.
type Dispatcher struct {
	store *store.Store
	log   *logging.Logger
	fcm   *FCMDataWake
	apns  *APNsWake
	now   func() time.Time
}

// NewDispatcher wires optional FCM and/or APNs senders. Nil senders skip
// that provider at dispatch time (counts as failure for metrics).
func NewDispatcher(st *store.Store, log *logging.Logger, fcm *FCMDataWake, apns *APNsWake) *Dispatcher {
	return &Dispatcher{
		store: st,
		log:   log,
		fcm:   fcm,
		apns:  apns,
		now:   time.Now,
	}
}

// SetClock replaces the wall clock (tests).
func (d *Dispatcher) SetClock(now func() time.Time) { d.now = now }

// WakeRecipient is best-effort: errors are logged; permanent invalid tokens
// are purged; day metrics are updated for the current UTC calendar day.
func (d *Dispatcher) WakeRecipient(ctx context.Context, recipient []byte) {
	if d == nil || d.store == nil {
		return
	}
	now := d.now()
	rows, err := d.store.ListRoutingPushTokensForRecipient(ctx, recipient, now)
	if err != nil {
		d.log.Warn(ctx, "push.wake.list_failed",
			logging.F(logging.KeyError, err.Error()),
		)
		return
	}
	if len(rows) == 0 {
		return
	}
	b64 := EncodeRecipientB64(recipient)
	var nOK, nFail int64
	dayUTC := time.Date(now.UTC().Year(), now.UTC().Month(), now.UTC().Day(), 0, 0, 0, 0, time.UTC)

	for _, row := range rows {
		var sendErr error
		switch row.Provider {
		case "fcm":
			if d.fcm == nil {
				nFail++
				continue
			}
			sendErr = d.fcm.SendWakeClassify(ctx, row.PushToken, b64)
		case "apns":
			if d.apns == nil {
				nFail++
				continue
			}
			sendErr = d.apns.SendWakeClassify(ctx, row.PushToken, b64)
		default:
			nFail++
			continue
		}

		if sendErr == nil {
			nOK++
			continue
		}
		nFail++
		var perm *PermanentTokenError
		if errors.As(sendErr, &perm) {
			if err := d.store.DeleteRoutingPushTokenRow(ctx, recipient, row.Provider, row.PushToken); err != nil {
				d.log.Warn(ctx, "push.wake.purge_token_failed",
					logging.F(logging.KeyError, err.Error()),
				)
			}
		} else {
			d.log.Warn(ctx, "push.wake.send_failed",
				logging.F(logging.KeyError, sendErr.Error()),
			)
		}
	}

	if err := d.store.MergeDayMetrics(ctx, dayUTC, nOK, nFail, 0); err != nil {
		d.log.Warn(ctx, "push.wake.metrics_failed",
			logging.F(logging.KeyError, err.Error()),
		)
	}
}
