# Tasks — housing active agreement operations

## Spec authoring (this change)

- [x] A.1 Create change scaffold: proposal, design, four capability specs.
- [x] A.2 Delta: unanimous activation notification in `housing-plan-proposal-offer-flow`.
- [ ] A.3 Editorial pass after implementation feedback (iteration 2+).

## Pass 1 — Hub and data model

- [x] 1.1 Replace `HousingActivePlanScreen` stub with hub menu (six actions + agreement header).
- [x] 1.2 Drift schema: `RealizedExpense`, attachment metadata, per-participant acceptance rows.
- [x] 1.3 Repository + draft save for realized expense (local only, not yet synced).

## Pass 2 — Entry (`housing-realized-expense-entry`)

- [ ] 2.1 `HousingRealizedExpenseFormScreen`: plan line picker (active plan only).
- [ ] 2.2 Fields: amount, payment date, payer participant, expense type (normal / reimbursement / advance).
- [ ] 2.3 Proof capture: crop, compress, persist path + display name.
- [ ] 2.4 Submit hands off to ledger propose flow.

## Pass 3 — Ledger (`housing-realized-expense-ledger`)

- [ ] 3.1 Encrypted envelope kinds + client protocol doc (propose, accept, reject, amend).
- [ ] 3.2 Review queue UI: accept / reject with required justification on reject.
- [ ] 3.3 Unanimous acceptance gate before expense affects balances.
- [ ] 3.4 Resubmit after rejection (new proposal id, lineage to prior).
- [ ] 3.5 Monthly summary + balances screens (hub routes).
- [ ] 3.6 Budget-cap confirmation when realized amount exceeds plan line cap (D.2 from unified-expense-entry).
- [ ] 3.7 Notifications: peer submitted expense; optional payment-responsible reminders (D.3).
- [ ] 3.8 Licensing: first realized expense sync marks plan active use.

## Pass 4 — Amendment & closure (`housing-agreement-amendment-and-closure`)

- [ ] 4.1 Read-only “view current plan” from active revision snapshot.
- [ ] 4.2 Amendment entry: one change type per proposal; wire to existing renegotiation / offer flow.
- [ ] 4.3 Enforce: roster changes require end + new agreement with fork.
- [ ] 4.4 Agreement end + fork plan for renewal.

## Pass 5 — Portability (`housing-agreement-data-portability`)

- [ ] 5.1 Export JSON: housing module, single agreement, revision chain, checksum.
- [ ] 5.2 Import: validate checksum + format version; reject tampered payloads.
- [ ] 5.3 Hub export/import screen + security copy (plaintext file).

## Pass 6 — Negotiation integration

- [ ] 6.1 Implement offer-flow task **1.23** (activation notification → hub).
- [ ] 6.2 Post-activation onboarding swiper (deferred — see `repo-maintenance-backlog`).

## Dependencies

- Stable unanimous activation (`housing-plan-proposal-offer-and-responses`).
- Connected contacts + steady-state sync (`contacts-module`, `privacy-first-sync-architecture`).
- `ExpensePlanLineForm` / active `PlanLine` model (`housing-unified-expense-entry`).
