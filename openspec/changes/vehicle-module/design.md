## Context

The product splits vehicle concerns into two licensed modules:

| Module | Identifier | Primary user |
| --- | --- | --- |
| **Véhicule** | `vehicle` | Owner who registers and maintains vehicle facts |
| **Partage de véhicule** | `vehicle-sharing` | Owner who shares **and/or** any participant who borrows |

This design covers **`vehicle` only**. Borrower usage entry, sharing relationships, and expense reconciliation windows are in `vehicle-sharing-module`.

Constraints:

- Local-first Flutter app; facts stored separately from derived metrics.
- One **fixed owner** per vehicle record for the lifetime of that record in the app.
- Vehicle kind is descriptive (car, truck, motorcycle, boat); behavior is shared unless a kind-specific rule is explicitly added later.

## Goals / Non-Goals

**Goals:**

- Coherent owner-side domain model (vehicle, owner use sessions, fuel, maintenance, violations).
- Monotonic odometer validation and deterministic distance / consumption metrics for the **owner's full vehicle history**.
- Owner-only maintenance reminders (e.g., oil change every N km).
- Export package for vehicle sale; buyer imports on their own `vehicle` entitlement.

**Non-Goals:**

- Reservations / advance booking (wish list).
- Borrower-facing statistics (see `vehicle-sharing-module`).
- Expense allocation and sharing ratios (see `vehicle-sharing-module`).
- Telematics (OBD-II, GPS auto-trip detection).
- In-app ownership transfer (sale = export + new owner import).

## Decisions

- **Fixed owner per vehicle**
  - **Decision**: each `Vehicle` row names exactly one owner Contact (the local user when they create it). Borrowers never become owners through sharing.
  - **Rationale**: matches product rule "un véhicule == un propriétaire"; simplifies authority for edits and reminders.

- **Borrowers write usage facts on the owner's vehicle**
  - **Decision**: borrower-entered use sessions (specified in `vehicle-sharing-module`) append odometer/fuel **usage facts** to the same vehicle record the owner maintains; the owner's app holds the canonical ledger.
  - **Rationale**: one odometer timeline per vehicle; owner retains full history.

- **Owner-only maintenance reminders**
  - **Decision**: scheduled service reminders (distance- or time-based) fire only on the **owner's** device.
  - **Rationale**: borrower is not responsible for fleet maintenance scheduling.

- **Consumption metrics scope on owner device**
  - **Decision**: owner sees consumption per km and total distance for the **entire vehicle history** (and arbitrary windows). Borrower sees only their usage windows (sharing module).
  - **Rationale**: aligns cost/benefit: owner pays more for `vehicle` license and maintains the asset.

- **Vehicle kind is metadata**
  - **Decision**: store `vehicleKind` enum/string; no separate module per kind.
  - **Rationale**: user asked for one module covering car, truck, motorcycle, boat.

## Risks / Trade-offs

- **[Odometer conflicts when owner and borrower both log]** → Mitigation: monotonic validation with explicit correction flag; attribution on each reading (owner vs borrower session).
- **[Large export on old vehicles]** → Mitigation: export is explicit user action; format documented in `vehicle-data-portability`.
- **[Buyer import without seller relay history]** → Mitigation: export is factual snapshot; sharing relationships are not assumed to transfer unless specified in sharing module.
