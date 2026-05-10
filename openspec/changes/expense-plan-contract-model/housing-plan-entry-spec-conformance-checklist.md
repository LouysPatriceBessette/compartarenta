# Housing plan entry UI — spec conformance checklist

This checklist maps **OpenSpec requirements** to the current **housing plan draft flow** (`mobile/lib/screens/housing/housing_plan_screen.dart` and related local persistence). It is about **first-time / local authoring** (“saisie”), not the full sync product.

**Sources**

- `specs/expense-plan-structure-and-editor/spec.md`
- `specs/shared-agreement-contract-terms/spec.md`
- `specs/plan-projection-preview/spec.md`
- `specs/contract-unanimous-renegotiation/spec.md` (only where it touches editing vs. group law)
- `specs/plan-contract-proposal-payload/spec.md` (proposal packaging vs. draft editor)

**Legend**

| Status | Meaning |
|--------|---------|
| **Yes** | Implemented in the housing plan flow in a way that satisfies the requirement for local drafting. |
| **Partial** | Some behavior exists; gaps vs. the spec text or only documented in code, not in UI. |
| **No** | Not implemented in this flow (or only scaffolding exists elsewhere). |

---

## expense-plan-structure-and-editor

| # | Requirement / scenario (summary) | Status | Notes |
|---|-----------------------------------|--------|-------|
| E1 | Author a **detailed draft** expense plan locally (recurring + one-off ranges + ratios). | **Yes** | Wizard: expenses, categories, split step, persistence. |
| E2 | Recurring line with ratios summing to product tolerance → persisted and in summaries. | **Yes** | 100% weights (bps); summary uses ratios. |
| E3 | One-off estimate with min/max → **min ≤ max** validated, both stored for projection. | **Partial** | Range mode in line editor; confirm dedicated validation UX for all edge cases if required. |
| E4 | **Non-blocking encouragement** (checklist, tips, readiness, summary gaps). | **Partial** | Stepper + inline hints/snackbars; no dedicated checklist / readiness score. |
| E5 | **Readiness hints** when draft lacks key fields (ratios, period, …) without deleting work. | **Partial** | Validations on “Next”; not a standing checklist of gaps. |
| E6 | **Optional gate** before “Propose to group” with explanation when incomplete. | **No** | No “Propose to group” action in this screen. |
| E7 | Ratios stored **per line or per group** consistently. | **Yes** | `PlanRatio` line vs group scope. |
| E8 | Group-level ratios apply to bundled lines for projection/allocation. | **Yes** | Split UI and projection paths handle groups. |
| E9 | Draft remains **local** until user explicitly proposes. | **Partial** | Data stays on device; **explicit propose** from this UI is absent (`PlanAgreementProposalService` not wired from app screens). |

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
| A7 | Contract/plan edits after accept → **pending renegotiation** until unanimous accept. | **Partial** | Local proposal/revision tables and service exist; **housing UI** does not surface renegotiation lifecycle. |

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
| R1 | Edits after active unanimous agreement → **renegotiation draft** until proposed + unanimous. | **Partial** | Domain/service direction; **not exposed** in housing wizard copy or state. |
| R2 | “Propose changes to agreement” style entry. | **No** | Not in `HousingPlanScreen`. |

---

## plan-contract-proposal-payload (draft vs package)

| # | Requirement / scenario (summary) | Status | Notes |
|---|-----------------------------------|--------|-------|
| W1 | “**Propose to group**” builds a **self-contained** proposal package. | **No** | No button/workflow from housing UI; `PlanAgreementProposalService` unused from `lib/` screens. |
| W2 | Peer can **render** summary / projection from payload alone. | **No** | Transport and peer UI out of scope for this checklist item — not done in-app. |
| W3 | Payload includes **flexible clauses** when present. | **No** | Clauses not authorable in wizard; packaging not invoked from UI. |

---

## Suggested next work (priority for “full” spec alignment)

1. Add **preview / non-binding** copy (and optional banner) on the housing **summary** step.  
2. Align **summary numbers** with spec: either show **period-scoped** projection using `PlanProjection.projectTotalMinor` + documented one-off rule, or label monthly view explicitly as “per month” vs “over agreement period”.  
3. Surface **one-off projection rule** in UI (one line or link to help).  
4. Add **optional flexible clauses** field (bounded length) before “finish” or on a contract sub-step.  
5. Wire **“Propose to group”** (or equivalent) to `PlanAgreementProposalService` + completeness gate per `expense-plan-structure-and-editor`.  
6. Optional: **readiness checklist** or inline gap list instead of only step-gated snackbars.

---

_Last reviewed against the spec files in this change and `housing_plan_screen.dart` layout (wizard + summary)._
