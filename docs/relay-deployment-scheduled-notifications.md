# Scheduled housing payment reminders (relay cron)

Schema migration `0003_scheduled_notifications.sql` adds the fifth relay data
category: **scheduled notification housekeeping** (`scheduled_notification_targets`,
`scheduled_notification_fires`, `recipient_notification_timezone`).

## Environment variables

| Variable | Default | Purpose |
|----------|---------|---------|
| `REMINDER_CRON_ENABLED` | `false` | When `true`, the relay runs the reminder cron alongside the sweeper. |
| `REMINDER_CRON_INTERVAL` | `5m` | Cadence for claiming due `scheduled_notification_fires` rows. |

Payment reminder reconciliation uses the existing scheduling HTTP API:

- `POST /v1/scheduling/timezone` — upsert recipient IANA timezone (recomputes pending housing fires).
- `POST /v1/scheduling/housing/reconcile` — upsert/cancel housing payment targets (domain `housing_payment`).
- `POST /v1/scheduling/housing/cancel` — partial cancel by scope/period.
- `GET /v1/scheduling/pending-deliveries` — client fetch after wake push.
- `POST /v1/scheduling/ack-delivery` — mark a fired row consumed.

When a fire is due, the cron marks it `fired`, dispatches a wake push
(`kind=wake_for_inbox`), and exposes the row via `pending-deliveries`. The
mobile client builds the localized notification.

## Operator checklist

1. Deploy relay with migration `0003` applied (schema version 3).
2. Set `REMINDER_CRON_ENABLED=true` only after client reconciliation paths are deployed.
3. Verify `POST /v1/scheduling/timezone` returns 200 for an authenticated routing identity.
4. Confirm due fires move from `pending` to `fired` within one cron interval (see relay logs / metrics).
5. Cross-reference audit items in [`relay-audit-checklist.md`](./relay-audit-checklist.md) for scheduled-notification tables.

Domains reserved for follow-up client work (schema only today): `housing_proposal_deadline`,
`contacts_invitation_expiry`.
