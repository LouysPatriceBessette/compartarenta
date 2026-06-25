# Pass 3 — final QA notes and follow-up backlog

**Scope:** `housing-realized-expense-ledger` (pass 3), validated 2026-05-23.  
**Status:** Pass 3 shipped. Items 1–5 below were **implemented** (see `tasks.md` Q.1–Q.5). Items 6–7 were **decided: will not implement** (2026-06-16).

## Validated (no action required for pass 3 commit)

- Submitter does not see Accept / Reject on their own proposal (after payer auto-accept fix).
- Peer receives notification on new proposal; tap opens expense review detail (web + native).
- Reject sync notifies originator; originator sees rejection reason; **Resubmit** only on payer device.
- Unanimous accept → `published`; visible in **Current month expenses** and balances.
- Resubmit creates new proposal id; peer can accept again.
- No notification on accept (not in current spec — same as reject-only + propose notifications).

## Follow-up backlog (detailed QA / later implementation)

### UX and visibility

1. ~~**Submitter pending visibility**~~ — **Done** (Q.1): in-flight proposals surfaced for submitter.
2. ~~**Monthly expenses detail**~~ — **Done** (Q.2): drill-down row.
3. ~~**Proof viewer**~~ — **Done** (Q.3): local attachment viewer.
4. ~~**Optional notification on accept**~~ — **Done** (Q.4): peer accept notification when prefs allow.
5. ~~**Document picker QA**~~ — **Done** (Q.5): regression exercised.

### Rejection and resubmit policy

6. **Abandon rejected expense** — **Decided 2026-06-16: will not implement.** Keep correct-and-resubmit only; rejected rows stay in audit history.

7. **Resubmit requires changes** — **Decided 2026-06-16: will not implement.** Unchanged resubmit remains allowed (new proposal id, peers review again).

## Android E2E (Maestro)

Settlement-window hub gating is covered by Maestro scenarios under
`housing-post-agreement-settlement-window` / Pass 7 in `tasks.md`.
Realized-expense entry, review queue, and publish flows are **not** yet Maestro scenarios.

## Out of scope for this list

- Pass 4+ hub placeholders (view plan, amendment, export/import) — Pass 4 landed separately.
- Proof file sync to peers (protocol / relay; larger than UI-only viewer).
- Payment-responsible reminders (ledger spec D.3) — tracked in `housing-scheduled-payment-reminders`.
