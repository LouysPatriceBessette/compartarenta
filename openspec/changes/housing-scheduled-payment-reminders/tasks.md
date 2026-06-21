# Tasks — relay scheduled notifications

> **Implementation status (2026-06-21).** **Housing payment reminders** (relay
> schema v3, reconciliation API, reminder cron, client
> `HousingPaymentReminderService`, Settings category, overdue journal card, EN/FR/ES
> copy) are **implemented in the repo** for native (Android) paths. End-to-end
> field validation (activation → cron fire → FCM wake → notification) and
> audit/docs (**1.5**) remain **open**.

## 0. Product decisions

- [x] OQ.1 Relay replaces local scheduling for **housing payment** reminders.
- [x] OQ.2 Tiered before-date (W&lt;20 / 20–40 / &gt;40); **14:00** local; relay IANA timezone.
- [x] OQ.3 Overdue payment reminders in scope.
- [x] OQ.4 Fifth relay category; scheduling timestamps allowed.
- [x] OQ.5 Web out of scope.
- [x] OQ.6 Coverage: `unitMinor` + sliding period + carry between periods.
- [x] OQ.7 `everyNDays` sliding window.
- [x] OQ.8 Housing payment: unanimity-establishing client only for schedule reconciliation.

## 1. Relay (release + audit)

- [x] 1.1 Migration `0003_scheduled_notifications.sql` (`scheduled_notification_*`, `recipient_notification_timezone`) + `schema_shape_test.go`. *(See `relay/internal/store/schema/0003_scheduled_notifications.sql`; version bump asserted in `schema_shape_test.go`.)*
- [x] 1.2 Reconciliation ingest + timezone upsert + tiered `fire_at` computation (14:00 local). *(See `relay/internal/api/scheduling.go`, `relay/internal/store/scheduled_notifications.go`, `relay/internal/scheduling/firetimes.go` + tests.)*
- [x] 1.3 Reminder cron + metrics + `REMINDER_CRON_ENABLED`. *(See `relay/internal/remindercron/remindercron.go`, `relay/cmd/relay/main.go`.)*
- [x] 1.4 On fire: mark row, enqueue `scheduled_reminder_due`, dispatch wake. *(Fires claimed in store; wake push when `WakePushDispatchEnabled`; client pulls pending rows via `GET /v1/scheduling/pending` rather than a steady-state envelope — see `relay_scheduling.dart`.)*
- [ ] 1.5 Audit checklist + deployment docs. *(Push-token audit items exist; scheduled-notification operator docs not yet added to `docs/relay-deployment.md`.)*

## 2. Client — housing payment reminders

- [x] 2.1 Sliding-window period + carry attribution helper (adapt from chart carry). *(See `payment_period_coverage.dart`, `housing_payment_reminder_service.dart`; unit test in `payment_period_coverage_test.dart`.)*
- [x] 2.2 Reconciliation on E.1–E.4 and publish (unanimity sender); timezone upsert on E.1 + activation import. *(See `HandshakeOrchestrator._reconcileHousingPaymentRemindersAfterActivation`, `_maybeReconcileHousingRemindersAfterExpenseAccept`.)*
- [ ] 2.2b Settings timezone change → upsert + pending fire recompute when active housing plan. *(No listener on `AppPreferences` time-zone fields yet.)*
- [x] 2.3 Envelope codecs + metadata strip. *(Delivered via scheduling HTTP JSON codecs in `relay_scheduling.dart` / `RelayClient.fetchPendingReminderDeliveries` — not a steady-state encrypted envelope kind.)*
- [x] 2.4 Notification builder + Settings category + deep link. *(See `PushNotificationService.showLocalHousingPaymentReminderNotification`, Settings switch `notificationHousingPaymentReminders`; tap payload `housing_proposal:{planId}` — destination review tracked in `dev-ideas/2026-06-20-notification-list.md` #10–11.)*
- [x] 2.5 Overdue journal: local persistence + orange card in `HousingMonthlyExpensesScreen` (no navigation). *(Table `housingPaymentOverdueJournalEntries`; card in `housing_monthly_expenses_screen.dart`.)*
- [x] 2.6 l10n EN/FR/ES for overdue journal copy. *(ARB keys `housingOverdueJournalCardBody`, payment reminder push strings.)*

## 3. Tests

- [ ] 3.1 Relay: cron claim, tiered before-date table, timezone reschedule, skip past fires, 14:00-not-midnight. *(Tiered 14:00 table covered in `firetimes_test.go`; cron claim integration tests still open.)*
- [ ] 3.2 Client: coverage + carry; before-date vs overdue recipient rules; overdue journal card. *(Partial: `payment_period_coverage_test.dart` only.)*
- [ ] 3.3 Integration: activation → fire → wake → notification (native).

## Dependencies

- `closed-app-push-delivery`
- `housing-active-agreement-operations` (published expenses, activation)
- `housing-unified-expense-entry` (recurrence, payment responsible)
- Task **3.9** relay-visible expense metadata (align fields)
