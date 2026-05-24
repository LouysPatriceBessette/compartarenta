# Housing — active agreement operations (realized expenses)

## Why

Once a housing plan + agreement is **unanimously accepted** and **active**, participants need to **record realized expenses**, **review** peers’ submissions, **see balances**, and **maintain** the agreement (amendments, export, closure). Today [`HousingActivePlanScreen`](../../../mobile/lib/screens/housing/housing_active_plan_screen.dart) is a placeholder; realized-expense ledger behavior is implied by [`privacy-first-sync-architecture`](../../privacy-first-sync-architecture/specs/data-locality-and-client-storage/spec.md) and licensing (“realized expense sync”) but not specified for Housing UX.

## What changes

- **Active agreement hub** replacing the blank screen: menu routes to entry, monthly views, balances, plan read-only, amendment request, export/import.
- **Realized expense entry** linked to active `PlanLine` rows, optional proof attachments (crop/compress, user-visible storage paths).
- **Ledger lifecycle**: propose → unanimous peer accept → accepted ledger; reject with justification and resubmit.
- **Agreement-scoped export/import** (JSON, checksum, housing module only, one agreement including revision chain).
- **Plan amendment and closure** rules (what is a renegotiation vs new agreement for roster changes).

## Capabilities (this change)

| Capability | Role |
|------------|------|
| `housing-realized-expense-entry` | Capture UI, proof pipeline, link to plan line |
| `housing-realized-expense-ledger` | Sync, review, balances, monthly summaries, budget-cap alerts |
| `housing-agreement-amendment-and-closure` | In-force plan changes vs new agreement; fork on renewal |
| `housing-agreement-data-portability` | Export/import bundle per agreement |

## Relationship to existing changes

| Change | Relationship |
|--------|----------------|
| `housing-plan-proposal-offer-and-responses` | Negotiation ends in activation; **unanimous activation notification** routes here (delta in offer-flow spec). |
| `housing-unified-expense-entry` | `ExpensePlanLineForm` models **plan lines**; this change models **realized expenses** (distinct entity). Deferred D.1–D.4 move here. |
| `expense-plan-contract-model` / `contract-unanimous-renegotiation` | Amendments reuse unanimous proposal semantics. |
| `privacy-first-sync-architecture` | Peer expenses are **proposals** until accepted locally. |
| `licensing-trial-and-plan-entitlement` | First **realized expense sync** starts trial (unchanged policy). |
| `client-db-exportability` | General export rules; this change adds **housing agreement bundle** specifics. |

## Out of scope (this change)

- **Post-activation onboarding swiper** (multi-card explainer) — tracked in `design.md` and `repo-maintenance-backlog`; copy not specified here.
- Relay protocol implementation details beyond message kinds named in specs (prefer client-first docs; relay delta only when required).
- Car-sharing module parity.

## Impact

| Area | Impact |
|------|--------|
| `mobile/lib/screens/housing/housing_active_plan_screen.dart` | Hub UI |
| New `mobile/lib/housing/realized_expense/` (suggested) | Entry, ledger, balances, export |
| `mobile/lib/db/app_database.dart` | New tables for realized expenses, attachments, acceptance matrix |
| Encrypted steady-state envelopes | New kinds for expense propose / accept / reject |
| `housing-plan-proposal-offer-and-responses` | Task 1.23 activation notification |
