## ADDED Requirements

### Requirement: Terminology — Propriétaire and Emprunteur
User-facing copy SHALL use **Propriétaire** (FR) / **Emprunteur** (FR) equivalents in each locale for the two sharing parties. Specifications use **owner** and **borrower** as English technical terms for the same roles.

### Requirement: Sharing links connect Propriétaire, one vehicle, and one Emprunteur
The system SHALL represent an approved sharing relationship as a **VehicleSharingLink** with at least:
- `vehicleId` (one specific vehicle owned by the Propriétaire)
- `ownerContactId`
- `borrowerContactId`
- `status` (pending, active, expired, revoked)

Exactly **two parties** participate in each link. There is no multi-borrower group entity beyond separate pairwise links per Emprunteur.

#### Scenario: Propriétaire offers one specific vehicle to a connected Contact
- **WHEN** a Propriétaire with effective `vehicle` and `vehicle-sharing` entitlement selects **one owned vehicle** and a **connected Contact** to invite
- **THEN** the system creates a sharing link in pending state for that vehicle and Contact only
- **THEN** the offer copy states that the Emprunteur accepts responsibilities tied to **that vehicle's** use

#### Scenario: Propriétaire is deemed to have accepted their own offer
- **WHEN** the Propriétaire sends a vehicle offer
- **THEN** the Propriétaire side of the link is treated as already accepted (no separate Propriétaire acceptance step)
- **THEN** the link activates only when the Emprunteur accepts

#### Scenario: Emprunteur accepts sharing
- **WHEN** an Emprunteur with effective PE (see `vehicle-sharing-licensing-and-delinquency`) accepts a pending offer
- **THEN** the link becomes active
- **THEN** the Emprunteur may log usage on **that vehicle only**

### Requirement: No reverse discovery path for Emprunteurs
The system MUST NOT provide a flow where an Emprunteur browses or requests access to unspecified vehicles from a Propriétaire's fleet. The **only** entry path is: **Propriétaire offers this vehicle → Emprunteur accepts or declines**.

#### Scenario: Borrower cannot request from owner vehicle list
- **WHEN** an Emprunteur wants access to a Propriétaire's vehicle
- **THEN** there is no UI to pick from the Propriétaire's vehicle list without a prior offer
- **THEN** the Emprunteur must wait for a Propriétaire-initiated offer for a specific vehicle

### Requirement: Offering sharing requires both vehicle modules on the Propriétaire
The system MUST NOT allow a Propriétaire to publish a vehicle offer unless they have effective entitlement on **`vehicle` and `vehicle-sharing`** (EV + PP), except during the vehicle trial waiver in `vehicle-module-licensing`.

#### Scenario: Propriétaire with vehicle only cannot offer
- **WHEN** a user has `vehicle` but not `vehicle-sharing` (and no trial waiver)
- **THEN** the offer action is unavailable or blocked with guidance to subscribe to `vehicle-sharing`

### Requirement: Borrowing requires vehicle-sharing on the Emprunteur device
An **Emprunteur** SHALL log usage only when they have effective **PE** (`vehicle-sharing` entitlement or trial waiver) and an **active** sharing link for that vehicle.

#### Scenario: Emprunteur without vehicle subscription uses shared vehicle
- **WHEN** participant B has `vehicle-sharing` only (PE) and an active link on A's vehicle
- **THEN** B can log usage on that vehicle
- **THEN** B cannot register a new owned vehicle

### Requirement: Multiple vehicles and multiple Emprunteurs
The system SHALL support:
- one Propriétaire sharing **multiple vehicles** (each with separate pairwise links),
- one Emprunteur using **multiple vehicles** (same or different Propriétaires),
- one Propriétaire **borrowing another Propriétaire's vehicle** while sharing their own.

#### Scenario: Propriétaire borrows while sharing out
- **WHEN** A shares their car with B and also has an active link as Emprunteur on C's vehicle
- **THEN** A can log owner uses on their car and Emprunteur uses on C's car
- **THEN** B can log Emprunteur uses on A's car only

### Requirement: Revoking sharing stops new Emprunteur usage
When a Propriétaire revokes a sharing link, the Emprunteur MUST NOT log new usage on that vehicle after revocation. Historical usage facts remain on the vehicle record for the Propriétaire's reconciliation.

#### Scenario: Propriétaire revokes Emprunteur
- **WHEN** the Propriétaire revokes an active link with B
- **THEN** B can no longer start new uses on that vehicle
- **THEN** past uses attributed to B remain on the Propriétaire's vehicle record
