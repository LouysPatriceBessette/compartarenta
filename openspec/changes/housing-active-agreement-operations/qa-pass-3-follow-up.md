# Pass 3 — final QA notes and follow-up backlog

**Scope:** `housing-realized-expense-ledger` (pass 3), validated 2026-05-23.  
**Status:** Pass 3 shipped; items below are **deferred** to detailed QA or later passes unless noted.

## Validated (no action required for pass 3 commit)

- Submitter does not see Accept / Reject on their own proposal (after payer auto-accept fix).
- Peer receives notification on new proposal; tap opens expense review detail (web + native).
- Reject sync notifies originator; originator sees rejection reason; **Resubmit** only on payer device.
- Unanimous accept → `published`; visible in **Current month expenses** and balances.
- Resubmit creates new proposal id; peer can accept again.
- No notification on accept (not in current spec — same as reject-only + propose notifications).

## Follow-up backlog (detailed QA / later implementation)

### UX and visibility

1. **Submitter pending visibility** — After proposing, the payer has no hub trace until the expense is `published` (monthly list is published-only). Add a surface for in-flight proposals (e.g. review list with “Waiting for others”, or a hub section).

2. **Monthly expenses detail** — List shows amount and date only; add line title, payer, status, and navigation to review/detail.

3. **Proof viewer** — Proofs are stored locally; relay carries metadata only. No UI to open/view attachments on submit or review screens.

4. **Optional notification on accept** — Spec today: notify on propose (review) and on reject (originator). Consider “{name} accepted expense E” if product wants parity.

5. **Document picker QA** — Camera and gallery exercised; file/document picker path not fully regression-tested.

### Rejection and resubmit policy

6. **Abandon rejected expense** — Allow the originator to **drop** a rejected proposal instead of being steered only toward correct-and-resubmit (audit history retained; no new proposal required).

7. **Resubmit requires changes** — Block resubmit when nothing changed vs. the rejected version (amount, date, line, kind, beneficiary, proofs). Today resubmit without edits is allowed; product rule should require a real correction.

## Suggested ordering (non-binding)

| Priority | Item | Rationale |
|----------|------|-----------|
| P1 | 7 | Prevents noise and duplicate ledger rows |
| P1 | 6 | Completes rejection lifecycle |
| P2 | 1 | Submitter confidence after submit |
| P2 | 3 | Trust in proof-based rejections |
| P3 | 2, 4, 5 | Polish and optional notifications |

## Out of scope for this list

- Pass 4+ hub placeholders (view plan, amendment, export/import).
- Proof file sync to peers (protocol / relay; larger than UI-only viewer).
- Payment-responsible reminders (ledger spec D.3, optional).
