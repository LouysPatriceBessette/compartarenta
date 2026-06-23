# Device data import and restore protocol

## Overview

Full-device backup restores all local operational tables after device replacement.
Import is gated by an **active paid store subscription** covering housing (not entitlement-server state).

After a successful local import, the client requests **installation identity migration** so
entitlement-server records keyed to the old `participant_installation_id` are rebound to the
new installation id.

## Export bundle (JSON)

| Field | Description |
| --- | --- |
| `formatVersion` | Integer; current `1` |
| `exportedAt` | ISO-8601 UTC timestamp |
| `bundleKind` | `device_full` |
| `migration` | `participantInstallationId`, `housingPlanIds` (bare UUID per housing plan; module is implicit) |
| `tables` | Map of Drift table key → array of row JSON objects |
| `checksum` | SHA-256 hex of canonical `jsonEncode` of payload **excluding** `checksum` |

Optional canonical restore metadata (future):

| Field | Description |
| --- | --- |
| `canonicalRestore` | When true, UI offers participant identity selection |
| `participantRestoreChoices` | `{ participantId, displayName }[]` |

## Import order

1. Validate store subscription (import gate).
2. Parse JSON, verify `formatVersion` and `checksum`.
3. If local DB non-empty → user confirms full replace.
4. Wipe operational tables and import rows in one transaction.
5. On success only → migration request (below).
6. Surface success or failure to the user.

## Installation migration (envelope kind 15)

Wire constant: `EnvelopeKind.participantInstallationMigration = 15`.

Transport: `POST /v1/participant-installation-migrate` on the **relay** (not peer envelope routing).

Request body:

```json
{
  "envelope_kind": 15,
  "plan_id": "housing:…",
  "old_participant_installation_id": "…",
  "new_participant_installation_id": "…"
}
```

Relay forwards to entitlement `POST /v1/installations/migrate` (internal).

Responses:

| HTTP | Meaning |
| --- | --- |
| 204 | Migration succeeded |
| 400 | `plan_id_mismatch`, `invalid_request` |
| 404 | `old_installation_not_found` |
| 502/503 | Entitlement unavailable (client retries transport) |

Client transport retries: `RelayHttpPolicy` (3 retries). Persistent failure → localized network
message + **Retry migration** in Settings (no re-import).

## Entitlement migration semantics

On success, entitlement replaces `old_participant_installation_id` with
`new_participant_installation_id` in all durable records:

- `housing_plan_rosters`
- `housing_expense_decisions`
- `housing_plan_licenses`
- `license_receipts`
- `installations` (trial flags merged onto new id; old row removed when safe)

`plan_id` must match: the old id must appear in the active roster for that plan.
