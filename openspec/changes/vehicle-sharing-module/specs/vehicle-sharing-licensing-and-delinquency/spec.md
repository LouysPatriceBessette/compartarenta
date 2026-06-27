## ADDED Requirements

### Requirement: Three entitlement roles in a two-party sharing relationship
A sharing relationship between a **Propriétaire** (owner) and an **Emprunteur** (borrower) involves three functional entitlement roles, mapped to store modules as follows:

| Role code | Meaning | Store module | Device |
| --- | --- | --- | --- |
| **EV** | Vehicle entity (owned vehicle data) | `vehicle` | Propriétaire |
| **PP** | Propriétaire-side sharing (offer, receive borrower data) | `vehicle-sharing` | Propriétaire |
| **PE** | Emprunteur-side sharing (accept offer, submit usage data) | `vehicle-sharing` | Emprunteur |

`vehicle-sharing` is one purchasable module; **PP** and **PE** are role-specific gates on the Propriétaire and Emprunteur devices respectively.

### Requirement: Delinquency grace is one week per module
When any of EV, PP, or PE enters delinquency (unpaid after renewal), that module instance SHALL enter a **1-week grace period** consistent with `delinquency-grace-readonly-and-export`, then transition to the module-specific restrictions below. Accumulated local data SHALL remain exportable at all times (same rule as housing).

#### Scenario: Grace period applies independently per role
- **WHEN** the Propriétaire's `vehicle` subscription becomes unpaid
- **THEN** only EV (and dependent PP behavior per below) is affected after grace
- **THEN** the Emprunteur's PE state is unchanged unless their own `vehicle-sharing` subscription lapses

### Requirement: EV delinquent after grace — read-only vehicle data; PP disabled
After grace, if **EV alone** (`vehicle` on the Propriétaire device) is delinquent:

- EV is **read-only** for that Propriétaire's vehicle data (no new owner-side edits).
- **PP is disabled** on the Propriétaire device:
  - cannot offer the vehicle to new Emprunteurs or withdraw an active offer through normal publish flows;
  - pending offers in flight expire on their own;
  - cannot receive new usage data from Emprunteurs — Emprunteurs receive a **clear error** explaining that the Propriétaire's vehicle license is inactive.

#### Scenario: Borrower submit fails when owner EV delinquent
- **WHEN** an Emprunteur attempts to transmit usage data after the Propriétaire's EV has left grace as delinquent
- **THEN** the submission fails with an explicit reason referencing the Propriétaire's inactive vehicle license
- **THEN** no silent drop occurs without user-visible feedback

### Requirement: PP delinquent after grace — EV normal; PP disabled
After grace, if **PP alone** (`vehicle-sharing` on the Propriétaire device, while `vehicle` remains paid) is delinquent:

- **EV continues to operate normally** (full owner toolkit on owned vehicles).
- **PP is disabled** with the same restrictions as in the EV-delinquent case for offering, withdrawing offers, and receiving Emprunteur data.

#### Scenario: Owner maintains solo vehicle while PP delinquent
- **WHEN** the Propriétaire's `vehicle-sharing` is delinquent after grace but `vehicle` is active-paid
- **THEN** the Propriétaire can still log fuel, maintenance, and owner uses on owned vehicles
- **THEN** the Propriétaire cannot publish or manage sharing offers until PP is restored

### Requirement: PE delinquent after grace — Emprunteur sharing disabled
After grace, if **PE alone** (`vehicle-sharing` on the Emprunteur device) is delinquent:

- **PE is disabled** on the Emprunteur device:
  - cannot enter or transmit new usage data;
  - cannot accept a vehicle offer;
  - does not receive new vehicle offers from Propriétaires.

#### Scenario: Delinquent borrower cannot accept a new offer
- **WHEN** an Emprunteur's `vehicle-sharing` is delinquent after grace
- **THEN** inbound vehicle offers are not surfaced to that Emprunteur
- **THEN** any accept action is blocked with guidance to restore PE

### Requirement: Export remains available under all delinquency states
Regardless of EV, PP, or PE delinquency, each affected user SHALL retain the ability to export their locally accumulated module data per `module-enable-disable-and-data-isolation` and housing export precedent.

#### Scenario: Delinquent owner exports vehicle history
- **WHEN** EV is read-only after grace
- **THEN** the Propriétaire can still export vehicle data from their device
