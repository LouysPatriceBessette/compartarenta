## Context

Housing currently models an agreement as either active or ended for realized-expense entry. That matches the first shipping pass, but it is too strict for move-out settlement: balances may remain non-zero for days or weeks after `periodEnd`, while the group may already need to start the next agreement.

This change stays entirely on the client / spec side. No relay-source change is needed because expenses already carry their own agreement scope (`planId` / `packageId`), and the new behavior is about local gating, date windows, and screen routing.

## Goals / Non-Goals

**Goals:**

- Define a narrow post-end settlement mode for an ended agreement.
- Keep month navigation deterministic and tied to agreement dates.
- Allow a successor agreement to coexist with a prior agreement that is only open for settlement.
- Preserve clear separation between the old agreement’s settlement history and the new agreement’s in-force activity.

**Non-Goals:**

- Reopening plan amendments on an ended agreement.
- Turning the settlement window into an unlimited grace period.
- Changing relay payloads, relay admission rules, or server storage.
- Redesigning the home selector or proposal flow beyond the minimum behavior needed to keep both agreements addressable.

## Decisions

### 1. Introduce a distinct settlement-open state

Ended agreements will not be treated as fully active again. Instead, the product will distinguish:

- **in-force**: normal active agreement behavior,
- **settlement-open**: ended agreement with non-zero balances, still allowed to record late settlement expenses,
- **closed**: ended agreement with zero balances or expired settlement window.

This keeps the exception narrow and avoids reopening unrelated flows such as amendments.

### 2. Use a one-calendar-month post-end window

The settlement exception is limited to one calendar month after `periodEnd`, using local calendar semantics instead of raw hour arithmetic. This matches the user-facing notion of “one month after the agreement ends” and avoids timezone-driven surprises.

Alternative considered: a fixed 30-day window. Rejected because calendar-month behavior matches the agreement/date UX used elsewhere in Housing.

### 3. Keep monthly navigation date-derived, not data-derived

The month picker will be bounded by agreement dates, not by whether expenses exist in a month. The base window is start-month through end-month inclusive. If `periodEnd` is within five calendar days of month end, the following month is also exposed. This gives a stable, explainable navigation range and aligns with the settlement use case.

Alternative considered: opening months only when at least one expense exists. Rejected because it hides valid empty settlement months and makes navigation unpredictable.

### 4. Scope late expenses to the ended agreement even when a new agreement exists

If the group starts a new agreement while the previous one is settlement-open, any late expense entered from the previous agreement remains attached to that previous agreement. The successor agreement does not absorb old settlement entries.

This prevents history contamination and keeps balances interpretable per agreement term.

## Risks / Trade-offs

- **Two agreements visible at once may confuse users** → Keep the previous agreement clearly labeled as ended / settlement-only and do not restore amendment actions there.
- **Calendar-month semantics can be implemented inconsistently** → Define them explicitly in spec scenarios and centralize the date-window helper in code.
- **Late entries could be abused to extend an agreement informally** → Restrict the exception to non-zero balances, one month maximum, and settlement-only operations.
- **Parallel agreement routing may expose edge cases in selectors / hub entry points** → Keep agreement identity explicit in navigation and test both old-term and new-term entry paths.
