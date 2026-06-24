# Spec — housing participation change

## Requirements

### Case #1 — Voluntary withdrawal

- WHEN an active member proposes voluntary withdrawal with a departure date (today or future) THEN a pending change is created and broadcast (kind 10 propose).
- Other active participants MUST acknowledge the notice; rejection is not offered.
- FROM the notice date, peers have **5 calendar days** to acknowledge manually; after that deadline, **every participant who has not acknowledged is deemed to have acknowledged by default**.
- The departure takes effect (side effects + notify kind 12 `effective`) **only on or after the chosen departure date**, and only when acknowledgement conditions are met:
  - if the departure date is **still in the future**, wait until that date even when every peer has already acknowledged;
  - if the departure date is **today or already reached**, apply when every peer has acknowledged **or** when the 5-day acknowledgement period ends.
- WHILE pending THEN major change is disabled; amendment remains enabled for non-leavers.
- WHEN effective THEN departing member is removed from the active roster, ratios redistributed, inactive participant created; early-withdrawal penalty applies per agreement rules when due.

### Case #2 — Ejection

- WHEN a decider proposes ejection THEN candidate hub tiles are disabled with ejection subtitle; other deciders vote via kind 10/11.
- WHEN unanimous THEN candidate departs with ratio redistribution and inactive participant; no penalty.

### Hub

- WHEN membership is `departed` THEN hub title uses **Past agreement** with departure date in range.
- WHEN participation change is pending THEN show dark-red banner below amendment banner if both exist.
- WHEN a due voluntary withdrawal becomes effective on hub load THEN broadcast notify `effective` to peers.

### Case #3 — Invite participant (guidance only)

- WHEN the user taps **I want to invite a participant** on Major change THEN an explanatory dialog opens (termination required + FAQ link).
- The app SHALL NOT start an in-app add-participant negotiation flow from this entry (product decision: terminate current plan first).

## Constraints

- At most one `pending` participation change per plan.
- No relay Go changes; client envelope kinds only.
- No immediate termination (`immediate_termination`) flow.
