## Context

Bojairũ is a local-first Flutter app where operational data (plans, participants, expenses, car usage logs, balances, proposals) must remain on-device by default. The client database is therefore a long-lived, evolving component that must support schema evolution (migrations) while keeping the app’s storage footprint small and exports understandable.

The product’s privacy posture (see `privacy-first-sync-architecture`) makes the local database a core “source of truth” for calculations. This design document makes an explicit, reviewable choice for the client DB and explains why alternatives were not selected.

## Goals / Non-Goals

**Goals:**
- Prioritize **minimal on-device storage footprint** over raw DB throughput.
- Support a **migration mechanism** for inevitable schema changes across app updates.
- Keep data **exportable** into a human-comprehensible format with minimal transformation.
- Use a storage approach that is stable and widely understood in the Flutter ecosystem.

**Non-Goals:**
- Optimizing for multi-tenant server throughput (this is per-device storage).
- Selecting a sync protocol (covered elsewhere).
- Implementing the full domain schema in this change (this change is about the DB choice and requirements).

## Decisions

### Decision: Use SQLite (relational) with a migration-capable access layer (Drift)

- **Choice**: SQLite as the on-device storage engine, accessed via a typed Dart layer that supports schema migrations (e.g., Drift).
- **Rationale (aligned with constraints):**
  - **Disk footprint**: normalized relational schema reduces duplication (shared references instead of embedded copies). SQLite storage is compact and predictable.
  - **Migrations/versioning**: SQLite + a migration layer provides a clear, testable migration story across versions.
  - **Exportability**: although document models can look “JSON-like”, a relational model can still export human-readable data via structured export formats (JSON with references, or denormalized views) with minimal and deterministic transformation.
  - **Robustness**: SQLite is mature and well understood, with predictable failure modes and extensive tooling.

### Decision: Enforce forward-only migrations for released schemas; allow explicit resets in dev

- **Choice**: treat released schema versions as forward-only (no downgrade dependency). For unreleased development iterations, allow an explicit dev-only “reset local DB” mechanism to unblock rapid schema evolution.
- **Rationale**:
  - **User safety**: release builds must not silently delete operational data.
  - **Developer velocity**: during development, schema churn is expected; explicit resets avoid spending time writing throwaway migrations.
  - **Clarity**: separating policies reduces accidental “wipe” logic leaking into production.

### Alternatives considered (not selected)

- **Isar (object/document-ish)**
  - **Pros**: ergonomic object storage, fast queries.
  - **Not selected because**: object/document models can increase on-disk duplication depending on modeling, and migration/export guarantees become more library-specific. Disk usage is a primary constraint.

- **Hive (key-value / box store)**
  - **Pros**: simple, lightweight for small settings-like data.
  - **Not selected because**: complex query patterns and relationships across many entities become harder to model and export cleanly; long-lived schema evolution becomes more ad-hoc.

- **ObjectBox**
  - **Pros**: strong performance and object model.
  - **Not selected because**: larger dependency surface and a more specialized ecosystem; choice is harder to audit and reason about compared to SQLite for the “small footprint + migration” priority.

- **Plain JSON files**
  - **Pros**: export-friendly by default.
  - **Not selected because**: concurrency, corruption resistance, indexing, and migration/versioning are significantly harder to implement safely than using a DB engine.

## Risks / Trade-offs

- **[Relational schema complicates “as-is” export] → Mitigation**: define a deterministic export format (JSON with stable IDs and optional denormalized views) and keep export logic versioned.
- **[Migration bugs] → Mitigation**: require migration tests and a clear schema versioning strategy (linear versions, forward-only migrations).
- **[Premature optimization debates] → Mitigation**: treat performance as non-primary; measure only if real-user workloads demonstrate issues.
- **[Dev reset mechanism leaks into release] → Mitigation**: guard reset behind build-time flags and/or debug-only UI; add tests or CI checks to prevent release exposure.

