## 1. Domain and state machine

- [ ] 1.1 Define plan lifecycle states: free/unlinked, linked-not-active, active-trial, active-paid, delinquent-grace, delinquent-readonly.
- [ ] 1.2 Define events that transition states: second participant linked, realized expense sync, payment success, payment failure, grace expiry.

## 2. Notifications and UX

- [ ] 2.1 Implement trial reminder schedule: 2 weeks remaining, 1 week remaining, daily for last 4 days.
- [ ] 2.2 Implement delinquency reminders: daily to all participants during 1-week grace.
- [ ] 2.3 Implement read-only mode UX and clear banner explaining what is blocked and why.

## 3. Licensing model

- [ ] 3.1 Implement per-participant license checks and plan-level enforcement.
- [ ] 3.2 Implement plan-aligned renewal date once all required licenses are paid.

## 4. Export and legal documentation

- [ ] 4.1 Implement export flows that remain available in read-only mode so participants can always retrieve their history.
- [ ] 4.2 Add a legal/disclosures document describing dispute-limited behavior and that the app is not legal advice.

## 5. Tests

- [ ] 5.1 Unit tests for state machine transitions and time-based reminders.
- [ ] 5.2 Integration tests: active use triggers trial; trial expiry gating; delinquency grace then read-only; export available when read-only.

