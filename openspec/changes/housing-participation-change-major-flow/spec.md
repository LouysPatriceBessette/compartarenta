# Spec — housing participation change

## Requirements

### Case #1 — Immediate termination

- WHEN an active member proposes immediate termination THEN a pending change is created and broadcast (kind 10).
- WHEN any decider rejects THEN status becomes `aborted` and hub returns to normal.
- WHEN all active members accept THEN agreement closes for all and memberships become `departed`.
- WHILE pending THEN major change and amendment hub tiles are disabled for all participants.

### Case #2 — Voluntary withdrawal

- WHEN proposer selects a future departure date THEN an informational notify (kind 12) is broadcast.
- WHILE pending THEN major change is disabled; amendment remains enabled.
- WHEN local calendar date reaches departure date on resume/inbox THEN departing member is removed from active roster, ratios redistributed, inactive participant created.

### Case #3 — Ejection

- WHEN a decider proposes ejection THEN candidate hub tiles are disabled with ejection subtitle; other deciders vote via kind 10/11.
- WHEN unanimous THEN candidate departs with ratio redistribution and inactive participant; no penalty.

### Hub

- WHEN membership is `departed` THEN hub title uses **Past agreement** with departure date in range.
- WHEN participation change is pending THEN show dark-red banner below amendment banner if both exist.

## Constraints

- At most one `pending` participation change per plan.
- No relay Go changes; client envelope kinds only.
