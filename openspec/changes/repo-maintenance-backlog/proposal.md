## Why

Cross-cutting engineering work (tooling, CI, Gradle, housekeeping docs)
does not always map to a product feature or to relay operations. Without
a dedicated place, those items get parked in unrelated runbooks or lost.

## What Changes

- Introduce an OpenSpec **maintenance backlog** change: a single spec and
  tasks file where future items of this class are recorded and tracked.
- No product behaviour is defined here beyond “maintain a backlog and
  close items when done.”

## Capabilities

### New Capabilities

- `engineering-maintenance-backlog`: Holds requirements for how backlog
  items are written and a living list of deferred engineering tasks.

### Modified Capabilities

<!-- None. -->

## Impact

- **Process only**: gives contributors a canonical location for deferred
  hygiene work (build tooling, repo-wide chores unrelated to a feature
  change).
- **Relay / mobile product specs**: unchanged; this change does not
  alter functional requirements elsewhere.
