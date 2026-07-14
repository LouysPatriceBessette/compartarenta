## ADDED Requirements

### Requirement: Canonical backlog for deferred engineering chores

The repository SHALL maintain an OpenSpec change named
`repo-maintenance-backlog` that records **deferred** engineering tasks
which are **not** tied to a single product capability (examples: Gradle
/Java toolchain hygiene, CI-only fixes, repo-wide lint policy).

#### Scenario: Add a new backlog item

- **WHEN** a contributor identifies work that should not block a feature
  or relay change but must not be forgotten
- **THEN** they add a row to `tasks.md` under this change (or extend this
  spec with a short scenario) so the item is discoverable in review and
  planning.

#### Scenario: Complete a backlog item

- **WHEN** the work is implemented and merged
- **THEN** the corresponding task is marked done or removed from
  `tasks.md`, and any durable outcome is referenced (file path, doc, or
  follow-up change id) so the backlog stays truthful.

### Requirement: Backlog items stay honest about scope

Items in this backlog SHALL state which parts of the repo they touch
(mobile, relay, docs, CI) and SHALL NOT imply relay VPS steps when the
work only affects the Flutter client (and vice versa).

#### Scenario: Relay runbooks stay focused

- **WHEN** a task is purely client or tooling hygiene
- **THEN** it is listed only under this maintenance change, not in
  `docs/relay-deployment.md` or other relay-only runbooks unless it
  genuinely affects relay deployment.

### Requirement: Housing balances SVG overflow and visual upgrade are one delivery

When the housing balances chart needs work for **inactive participants** that
push beyond the eight active-roster due-split layouts (overflow / clipped
labels), the same implementation pass SHALL also improve the currently
summary-quality / rudimentary SVG presentation (layout, legend, readability).
Neither item SHALL be closed alone while the other remains open.

#### Scenario: Overflow fix ships with visual polish

- **WHEN** contributors address the inactive-participant balance-chart overflow
  bug (or the visual SVG upgrade)
- **THEN** both the overflow/layout fix and the visual upgrade land in the same
  delivery (linked tasks in `tasks.md`)

### Requirement: Flutter web is never a product backlog target

Flutter web is a **developer-only** multi-instance QA convenience. OpenSpec
backlog and product specs SHALL NOT carry **pending** tasks that assume a
production web app, production web origin, or “before shipping web” gates.
Dev-only notes (CORS for `localhost` QA, etc.) MAY remain in ops docs without
a pending product task.

#### Scenario: No pending “production web” chores

- **WHEN** a backlog or product task is framed as prep for shipping a web
  product surface
- **THEN** it is removed or rewritten so it does not depend on web-as-product
