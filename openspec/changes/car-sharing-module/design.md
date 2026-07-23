## Context

Bojairũ is a local-first Flutter application intended to help multiple people share expenses equitably with minimal manual errors. The existing context focuses on shared-apartment expenses. This change introduces a second domain: sharing a car among participants, which has vehicle-specific data (odometer readings, reservations) and derived metrics (distance, consumption per km, usage ratios) that influence cost allocation.

Constraints and assumptions for this design:
- Mobile-first UX; data storage is local and query-driven.
- Derived metrics MUST be deterministic from stored facts (e.g., odometer logs + fuel purchases).
- The new car-sharing module should remain decoupled enough to evolve independently, while reusing shared concepts (participants, shared expenses, settlements) where possible.

## Goals / Non-Goals

**Goals:**
- Introduce a coherent car-sharing domain model (vehicle, participants, uses/trips, reservations, expenses, allocations).
- Ensure primary inputs are easy to capture and validate (odometer monotonicity; reservation conflicts).
- Provide deterministic computations for:
  - distance traveled per use and per user over time windows
  - consumption per km from fuel purchases + distance
  - usage ratio per user as an input into allocation rules
- Support fair cost sharing with configurable allocation rules (equal / usage-weighted / fixed ratios).
- Keep the design compatible with future privacy-first sync (verifiable derivations), without implementing sync in this change.

**Non-Goals:**
- Advanced telematics integrations (OBD-II, GPS trip detection) in the initial iteration.
- Complex recurring reservation rules, multi-vehicle fleets, or enterprise scheduling.
- Automated reconciliation of fuel purchases to specific trips beyond basic date/range associations.

## Decisions

- **Domain separation with shared primitives**
  - **Decision**: model car sharing as a distinct module with its own entities, while reusing shared primitives (participants, money, timestamps, attachments).
  - **Rationale**: prevents apartment-expense requirements from being polluted with vehicle-specific rules, and keeps future extensions clean.
  - **Alternatives**:
    - Single “expense plan” with optional car fields → simpler initially, but becomes messy and error-prone as car features grow.

- **Fact-first storage, derived metrics computed**
  - **Decision**: store only facts (odometer readings, fuel purchase facts, reservation facts, expense facts). Compute distance, consumption, usage ratio as derived values.
  - **Rationale**: reduces inconsistency, supports explainability (“how did we compute this?”), and aligns with verifiable sync goals.
  - **Alternatives**:
    - Persist computed fields and “update in place” → risks drift and requires complex invalidation logic.

- **Odometer monotonicity rules**
  - **Decision**: enforce monotonic odometer readings per vehicle and validate each “use” has before/after readings or a clear exception state.
  - **Rationale**: odometer is the most reliable primitive for distance; monotonic validation prevents silent errors.
  - **Alternatives**:
    - Allow arbitrary readings and rely on user correction → more flexible, but increases error rate and disputes.

- **Reservation conflict handling**
  - **Decision**: treat overlapping reservations as invalid and block creation unless user chooses to override by editing existing reservation(s).
  - **Rationale**: prevents ambiguity about who had the car and encourages explicit coordination.
  - **Alternatives**:
    - Allow overlaps and “soft warn” → still leads to conflicts at time of use.

- **Allocation engine as a configurable policy**
  - **Decision**: define allocation as a policy with inputs (expenses, participants, usage ratios, optional fixed weights) producing per-user shares and settlement suggestions.
  - **Rationale**: supports equitable sharing across different households (equal split vs usage-weighted) without reworking the data model.
  - **Alternatives**:
    - Hard-code a single allocation approach → faster but doesn’t match real-world variability.

## Risks / Trade-offs

- **[Incorrect odometer entries] → Mitigation**: validation (monotonic), UI review flows, explicit “needs correction” status, and audit trail of edits.
- **[Consumption metric ambiguity] → Mitigation**: define explicit computation windows, show methodology, allow user to select which purchases are included.
- **[Feature scope creep] → Mitigation**: keep MVP to manual logs + basic metrics + basic reservations; defer integrations and advanced scheduling.
- **[Data model coupling] → Mitigation**: keep entities scoped to car-sharing module and expose only necessary shared abstractions.

