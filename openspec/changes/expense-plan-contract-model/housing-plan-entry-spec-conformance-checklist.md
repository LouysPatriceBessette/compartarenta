# Housing plan entry UI — spec conformance checklist

This checklist maps **OpenSpec requirements** to the current **housing plan draft flow** (`mobile/lib/screens/housing/housing_plan_screen.dart` and related local persistence). It is about **first-time / local authoring** (“saisie”), and it **references** the sibling change for **sending the proposal to connected participants** and the **response lifecycle** (see below).

**Sources (this change — `expense-plan-contract-model`)**

- `specs/expense-plan-structure-and-editor/spec.md`
- `specs/shared-agreement-contract-terms/spec.md`
- `specs/plan-projection-preview/spec.md`
- `specs/contract-unanimous-renegotiation/spec.md` (only where it touches editing vs. group law)
- `specs/plan-contract-proposal-payload/spec.md` (proposal packaging vs. draft editor)

**Sources (sibling change — `housing-plan-proposal-offer-and-responses`)**

- [`specs/housing-plan-proposal-offer-flow/spec.md`](../housing-plan-proposal-offer-and-responses/specs/housing-plan-proposal-offer-flow/spec.md) — deadline, relay send status, recipient Accept / Negotiate / Refuse, serial gate, broadcast to all, history, fork from invalidated offer; **proposer implicit accept** on send.
- [`proposal.md`](../housing-plan-proposal-offer-and-responses/proposal.md), [`design.md`](../housing-plan-proposal-offer-and-responses/design.md), [`tasks.md`](../housing-plan-proposal-offer-and-responses/tasks.md) — scope, transport notes, implementation tracking.

**Legend**

| Status | Meaning |
|--------|---------|
| **Yes** | Implemented in the housing plan flow in a way that satisfies the requirement for local drafting. |
| **Partial** | Some behavior exists; gaps vs. the spec text or only documented in code, not in UI. |
| **No** | Not implemented in this flow (or only scaffolding exists elsewhere). |

### Linked change: proposal send and responses

Items **E6**, **E9**, **W1**, **W2** (and peer-visible **P4** / **P5** once a draft is “in flight”), plus **home / workbench navigation** (selector when multiple plan entries: local draft, received offers, sent threads) and **fork gating + lineage**, are **blocked or incomplete** until the sibling OpenSpec change **`housing-plan-proposal-offer-and-responses`** is implemented. Track delivery there; when those flows ship, **re-run this checklist** and update the Status / Notes columns for the affected rows.

---

## expense-plan-structure-and-editor

| # | Requirement / scenario (summary) | Status | Notes |
|---|-----------------------------------|--------|-------|
| E1 | Author a **detailed draft** expense plan locally (recurring + one-off ranges + ratios). | **Yes** | 4-step wizard; full-screen `ExpensePlanLineForm` (amount, recurrence, per-line split, Like templates). |
| E2 | Recurring line with ratios summing to product tolerance → persisted and in summaries. | **Yes** | 100% weights (bps); summary uses ratios. |
| E3 | One-off estimate with min/max → **min ≤ max** validated, both stored for projection. | **Partial** | New saves use determined / budgeted (max) only (`amountMinor` + `amountIsBudgetCap`); legacy min/max rows may remain until edited. |
| E4 | **Non-blocking encouragement** (checklist, tips, readiness, summary gaps). | **Partial** | Stepper + inline hints/snackbars; no dedicated checklist / readiness score. |
| E5 | **Readiness hints** when draft lacks key fields (ratios, period, …) without deleting work. | **Partial** | Validations on “Next”; not a standing checklist of gaps. |
| E6 | **Optional gate** before “Propose to group” with explanation when incomplete. | **No** | No “Propose to group” action in this screen. **Implement with** [`housing-plan-proposal-offer-flow`](../housing-plan-proposal-offer-and-responses/specs/housing-plan-proposal-offer-flow/spec.md) (deadline + send to connected roster). |
| E7 | Ratios stored **per line or per group** consistently. | **Yes** | Unified flow: **per-line** `PlanRatio` only on save; orphan group-level rows stripped on plan load. |
| E8 | Group-level ratios apply to bundled lines for projection/allocation. | **Partial** | Legacy DB may still have groups; chart/summary use **one slice per line**; no group split step in wizard. |
| E9 | Draft remains **local** until user explicitly proposes. | **Partial** | Data stays on device; **explicit propose** from this UI is absent (`PlanAgreementProposalService` not wired from app screens). **Wire send path per** [`housing-plan-proposal-offer-flow`](../housing-plan-proposal-offer-and-responses/specs/housing-plan-proposal-offer-flow/spec.md). |

---

## shared-agreement-contract-terms

| # | Requirement / scenario (summary) | Status | Notes |
|---|-----------------------------------|--------|-------|
| A1 | Agreement defines a **period** (calendar bounds). | **Yes** | Plan dates step + `_persistPeriod`. |
| A2 | Cannot omit period when mandatory **for proposal** → block with message. | **Partial** | Period validated for the wizard; no proposal gate in this UI. |
| A3 | Early withdrawal: **minimum notice and/or penalty** floor. | **Yes** | Step 5 + `_validateStep`. |
| A4 | Reject contract when **both** notice and penalty cleared (if neither satisfies floor). | **Yes** | Same step validation. |
| A5 | Notice-only (or penalty-only per rules) can be valid. | **Yes** | `n > 0 \|\| p > 0` (and per-participant when not “same for all”). |
| A6 | **Optional flexible clauses** (free text, bounded) part of package. | **No** | `clauses` carried on persist paths; **no dedicated editor** in the housing wizard. |
| A7 | Contract/plan edits after accept → **pending renegotiation** until unanimous accept. | **Partial** | Local proposal/revision tables and service exist; **housing UI** does not surface renegotiation lifecycle. **Offer / response / invalidation UX:** [`housing-plan-proposal-offer-flow`](../housing-plan-proposal-offer-and-responses/specs/housing-plan-proposal-offer-flow/spec.md). |

---

## plan-projection-preview

| # | Requirement / scenario (summary) | Status | Notes |
|---|-----------------------------------|--------|-------|
| P1 | Projection of per-participant obligation over **agreement period** (recurring + one-offs per documented rule). | **Partial** | `PlanProjection` documents midpoint + months; **summary** emphasizes **monthly** share, not full-period totals in copy. |
| P2 | **Documented rule** for one-off min/max (midpoint / min / max) **disclosed** in-app or docs. | **Partial** | Documented in `plan_projection.dart` comments; **no in-app disclosure** string in housing summary. |
| P3 | Projection **updates** as amounts, ratios, or period change (no network). | **Yes** | Local state + `FutureBuilder`s / `setState`. |
| P4 | UI distinguishes **projection / preview** from agreed balances; **not binding** until unanimous accept. | **No** | Summary lacks a prominent “preview / non-binding” banner. |
| P5 | **Preview banner** when viewing draft or not-yet-unanimous proposal. | **No** | No such banner on housing summary. |
| P6 | Totals **scoped to agreement period** (or documented if open-ended). | **Partial** | Period stored; `projectTotalMinor` exists but summary path does not clearly present period-scoped totals to the user. |
| P7 | Shortening period **changes** projected totals per rules. | **Partial** | Underlying math can react to period; UI does not stress period-driven projection. |

---

## contract-unanimous-renegotiation (relevant to “saisie” only)

| # | Requirement / scenario (summary) | Status | Notes |
|---|-----------------------------------|--------|-------|
| R1 | Edits after active unanimous agreement → **renegotiation draft** until proposed + unanimous. | **Partial** | Domain/service direction; **not exposed** in housing wizard copy or state. **Fork / resubmit after invalidation:** [`housing-plan-proposal-offer-flow`](../housing-plan-proposal-offer-and-responses/specs/housing-plan-proposal-offer-flow/spec.md). |
| R2 | “Propose changes to agreement” style entry. | **No** | Not in `HousingPlanScreen`. **Overlaps offer flow** in [`housing-plan-proposal-offer-flow`](../housing-plan-proposal-offer-and-responses/specs/housing-plan-proposal-offer-flow/spec.md) (any participant may submit a new revision). |

---

## plan-contract-proposal-payload (draft vs package)

| # | Requirement / scenario (summary) | Status | Notes |
|---|-----------------------------------|--------|-------|
| W1 | “**Propose to group**” builds a **self-contained** proposal package. | **No** | No button/workflow from housing UI; `PlanAgreementProposalService` unused from `lib/` screens. **Package + send:** [`housing-plan-proposal-offer-flow`](../housing-plan-proposal-offer-and-responses/specs/housing-plan-proposal-offer-flow/spec.md). |
| W2 | Peer can **render** summary / projection from payload alone. | **No** | **Recipient preview + inbox:** [`housing-plan-proposal-offer-flow`](../housing-plan-proposal-offer-and-responses/specs/housing-plan-proposal-offer-flow/spec.md). |
| W3 | Payload includes **flexible clauses** when present. | **No** | Clauses not authorable in wizard; packaging not invoked from UI. |

---

## Suggested next work (priority for “full” spec alignment)

1. Add **preview / non-binding** copy (and optional banner) on the housing **summary** step.  
2. Align **summary numbers** with spec: either show **period-scoped** projection using `PlanProjection.projectTotalMinor` + documented one-off rule, or label monthly view explicitly as “per month” vs “over agreement period”.  
3. Surface **one-off projection rule** in UI (one line or link to help).  
4. Add **optional flexible clauses** field (bounded length) before “finish” or on a contract sub-step.  
5. Implement **`housing-plan-proposal-offer-and-responses`** ([`housing-plan-proposal-offer-flow/spec.md`](../housing-plan-proposal-offer-and-responses/specs/housing-plan-proposal-offer-flow/spec.md)): wire **“Propose to group”** (or equivalent) to `PlanAgreementProposalService`, relay fan-out, recipient UI, then **re-triage** rows **E6**, **E9**, **W1**, **W2** (and **P4** / **P5** if the shipped preview matches the sent package).  
6. Optional: **readiness checklist** or inline gap list instead of only step-gated snackbars.

---

_Last reviewed against the spec files in **this** change, `housing_plan_screen.dart` (wizard + summary), and the linked sibling **`housing-plan-proposal-offer-and-responses`**._
