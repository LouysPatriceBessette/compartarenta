## ADDED Requirements

### Requirement: No backward compatibility for pre-spec vehicle UI
The product has **no production users** and **no persisted vehicle-domain data** that must survive the transition from the early `car_sharing` prototype. Implementation SHALL **remove** obsolete vehicle UI, routes, and draft persistence — not keep them alongside the new hubs "for compatibility".

#### Scenario: Legacy route is removed not aliased
- **WHEN** the Vehicle module hub and Vehicle sharing hub ship
- **THEN** the app does not retain a `/car` route pointing at `CarSharingPlanScreen`
- **THEN** home **Vehicle** and **Vehicle sharing** tiles navigate only to the new hub routes

### Requirement: Remove obsolete car-sharing prototype surfaces
The following (non-exhaustive) prototype artifacts SHALL be **deleted or fully replaced** during vehicle module implementation, not deprecated in place:

- `CarSharingPlanScreen` and its draft-only flow under `mobile/lib/screens/car_sharing/`
- `CarSharingPlanDraft` / `carSharingPlanDraftJson` prefs storage used only by that prototype
- GoRouter route(s) that exist solely to serve the prototype (e.g. `/car`)
- Any home-screen "coming soon" stub once hubs and entitlement gating are wired

Replacement behavior lives entirely in `vehicle-hub-ui`, `vehicle-sharing-hub-ui`, and related domain specs.

#### Scenario: No dual vehicle entry paths
- **WHEN** vehicle hubs are enabled for a user
- **THEN** there is exactly one navigation path per module from app home to hub
- **THEN** no hidden or legacy menu opens the old plan screen

### Requirement: No data migration from prototype drafts
The app MUST NOT implement import, migration, or upgrade logic from `carSharingPlanDraftJson` or similar prototype blobs. Fresh vehicle records use the domain model in `vehicle-domain-model`.

#### Scenario: Prototype draft prefs are dropped
- **WHEN** vehicle module persistence ships
- **THEN** `carSharingPlanDraftJson` (or equivalent prototype key) is removed from preferences APIs
- **THEN** no code path reads legacy draft JSON to seed owned vehicles or sharing links

### Requirement: Specs supersede prototype code
Where OpenSpec vehicle requirements conflict with existing `car_sharing` prototype code, **OpenSpec wins**. Prototype code is removed rather than adapted piecemeal unless a spec explicitly references reusing a component (e.g., shared date pickers).
