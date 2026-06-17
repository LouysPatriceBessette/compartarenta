# Tasks — relay scheduled notifications

## 0. Product decisions

- [x] OQ.1 Relay replaces local scheduling (payment, proposal 1.4b, contacts 3.7).
- [x] OQ.2 Tiered before-date (W&lt;20 / 20–40 / &gt;40); **14:00** local; relay IANA timezone.
- [x] OQ.3 Overdue payment reminders in scope.
- [x] OQ.4 Fifth relay category; scheduling timestamps allowed.
- [x] OQ.5 Web out of scope.
- [x] OQ.6 Coverage: `unitMinor` + sliding period + carry between periods.
- [x] OQ.7 `everyNDays` sliding window.
- [x] OQ.8 Housing: unanimity-establishing client only; proposal author; invitation inviter.

## 1. Relay (release + audit)

- [ ] 1.1 Migration `0003_scheduled_notifications.sql` (`scheduled_notification_*`, `recipient_notification_timezone`) + `schema_shape_test.go`.
- [ ] 1.2 Reconciliation ingest + timezone upsert + tiered `fire_at` computation (14:00 local).
- [ ] 1.3 Reminder cron + metrics + `REMINDER_CRON_ENABLED`.
- [ ] 1.4 On fire: mark row, enqueue `scheduled_reminder_due`, dispatch wake.
- [ ] 1.5 Audit checklist + deployment docs.

## 2. Client — housing payment reminders

- [ ] 2.1 Sliding-window period + carry attribution helper (adapt from chart carry).
- [ ] 2.2 Reconciliation on E.1–E.4 and publish (unanimity sender); timezone upsert on E.1 + activation import.
- [ ] 2.2b Settings timezone change → upsert + pending fire recompute when active housing plan.
- [ ] 2.3 Envelope codecs + metadata strip.
- [ ] 2.4 Notification builder + Settings category + deep link.
- [ ] 2.5 Overdue journal: local persistence + orange card in `HousingMonthlyExpensesScreen` (no navigation).
- [ ] 2.6 l10n EN/FR/ES for overdue journal copy.

## 3. Client — proposal deadline + invitation expiry

- [ ] 3.1 Author: register/cancel on dispatch and response (`1.4b` → relay).
- [ ] 3.2 Inviter: register/cancel on create/revoke/extend (`3.7` → relay).
- [ ] 3.3 Enable Contacts invitation-expiration Settings switch.
- [ ] 3.4 Update task text in `housing-plan-proposal-offer-and-responses` and `contacts-module`.

## 4. Tests

- [ ] 4.1 Relay: cron claim, tiered before-date table, timezone reschedule, skip past fires, 14:00-not-midnight.
- [ ] 4.2 Client: coverage + carry; before-date vs overdue recipient rules; overdue journal card.
- [ ] 4.3 Integration: activation → fire → wake → notification (native).

## Dependencies

- `closed-app-push-delivery`
- `housing-active-agreement-operations` (published expenses, activation)
- `housing-unified-expense-entry` (recurrence, payment responsible)
- Task **3.9** relay-visible expense metadata (align fields)
