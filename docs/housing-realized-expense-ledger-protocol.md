# Housing realized expense ledger — client protocol

Steady-state encrypted envelopes between connected contacts. The relay stores opaque
`kind` bytes and `ciphertext` only; framing and AEAD are client-defined in
`mobile/lib/relay/envelopes.dart`.

## Envelope kinds

| Kind | Value | Purpose |
|------|-------|---------|
| `housing_realized_expense_propose` | 7 | New expense proposal |
| `housing_realized_expense_accept` | 8 | Participant accepts a proposal |
| `housing_realized_expense_reject` | 9 | Participant rejects with justification |
| `housing_realized_expense_amend` | *(reserved)* | Future: amend published row without overwriting acceptances |

## Propose (kind 7)

Inner JSON (UTF-8) inside AEAD body field `expense_json`:

- `expense_id` — stable proposal id (new id on resubmit; prior id in `prior_expense_id` on device only until synced)
- `package_id`, `plan_id`, `plan_line_id`, optional `plan_line_title`
- `amount_minor`, `currency`, `payment_date` (ISO-8601 UTC)
- `kind`: `normal` | `reimbursement` | `advance`
- `beneficiary_participant_id` (reimbursement)
- `participant_snapshots`: `[{ id, displayName, contactId? }]` for roster mapping on import
- `attachments`: `[{ display_file_name, content_hash? }]` (files stay local; hashes for audit)

**Idempotency:** receivers skip import when `expense_id` already exists.

## Accept / reject (kinds 8 / 9)

Inner JSON in `decision_json`:

- `expense_id`, `package_id`
- `decision`: `accepted` | `rejected`
- `justification` (reject; non-empty on sender)
- `participant_id` — sender’s participant id in their roster
- `participant_snapshots` — same shape as propose for mapping

Receivers update the matching `RealizedExpenseAcceptances` row, then recompute
expense status: **published** when all accepted, **rejected** when any reject.

## Publish gate (local)

Balances and monthly summaries include rows with status `published` only.

## Licensing

First successful propose send or peer propose import calls
`AppPreferences.markHousingPlanActiveUseStarted(planId)` (trial clock per
`licensing-trial-and-plan-entitlement`).

## Balance algorithm

See `mobile/lib/housing/realized_expense/realized_expense_balance.dart`:
split each published expense by plan-line weights; normal/advance credit the payer
from other participants’ shares; reimbursement credits the payer from the
beneficiary’s share only. Pairwise entries are netted before display.
