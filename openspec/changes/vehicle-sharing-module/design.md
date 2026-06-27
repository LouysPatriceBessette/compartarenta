## Context

Two-module licensing model using product roles **Propriétaire** and **Emprunteur**:

| Role | Subscriptions (store) | Functional roles |
| --- | --- | --- |
| **Propriétaire** | `vehicle` + `vehicle-sharing` | EV + PP |
| **Emprunteur** | `vehicle-sharing` only | PE |
| **Propriétaire solo** | `vehicle` only | EV |

See `vehicle-sharing-licensing-and-delinquency` for EV/PP/PE delinquency rules and `vehicle-module-licensing` for the 2-week vehicle trial (sharing waived during vehicle trial).

## Goals / Non-Goals

**Goals:**

- Propriétaire-initiated offer of **one specific vehicle** to a connected Contact; Emprunteur accepts (no reverse fleet browse).
- Exactly two parties per link; Propriétaire deemed to have accepted their own offer.
- Emprunteur writes usage facts on the Propriétaire's canonical vehicle record; no session-scoped fuel entry.
- Both parties may record **full-tank anchors**.
- Scoped visibility: Emprunteur metrics and reconciliation **only for their usage windows**.
- Fair expense allocation with explainable category rules.

**Non-Goals:**

- Advance reservations (wish list).
- Emprunteur maintenance reminders or lifetime owner metrics.
- Automatic ownership transfer on sale (sale export strips sharing metadata — see `vehicle-data-portability`).

## Decisions

- **Propriétaire-only offer path**
  - **Decision**: only the Propriétaire can offer a **specific** vehicle; Emprunteurs cannot browse a Propriétaire's fleet to request access.
  - **Rationale**: avoids ambiguous multi-vehicle discovery; matches Contacts-based invite flow.

- **Two parties; Propriétaire pre-accepted**
  - **Decision**: each link is pairwise; sending an offer counts as Propriétaire acceptance.
  - **Rationale**: only the Emprunteur must accept responsibilities.

- **Full-tank anchors by either party; no session fuel**
  - **Decision**: Propriétaire or Emprunteur may mark full-tank purchases; Emprunteurs do not log liters per session.
  - **Rationale**: session-level consumption estimates are unreliable; odometer/horometer readings are factual.

- **Three functional licenses in a relationship (EV, PP, PE)**
  - **Decision**: documented in `vehicle-sharing-licensing-and-delinquency` with 1-week grace per module instance.
  - **Rationale**: independent delinquency on owner vs borrower devices.

- **Boat horometer**
  - **Decision**: boats use engine hour meter readings; land vehicles use odometer. See `odometer-logging` and user-facing terminology dictionary.

## Risks / Trade-offs

- **[Emprunteur submits while Propriétaire PP disabled]** → Mitigation: clear error to Emprunteur; local queue may hold until restored or fail fast per spec.
- **[Borrower logs without owner online]** → Mitigation: local-first queue + relay sync; monotonic meter rules on merge.
