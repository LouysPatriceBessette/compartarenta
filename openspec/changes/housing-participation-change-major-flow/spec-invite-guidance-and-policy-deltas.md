# Spec — housing policy clarifications (contacts, overlap, vote expiry)

Delta requirements recorded alongside implementation of invite-participant guidance and related gates.

## ADDED Requirements

### Requirement: Invite participant on Major change shows guidance only

The **Major change** screen SHALL include a fourth action **I want to invite a participant** (localized). Tapping it SHALL open an explanatory dialog stating that adding a participant requires **terminating the current plan** and starting a new agreement. The dialog SHALL link to the in-app FAQ anchor `housing-invite-participant`.

#### Scenario: User opens invite guidance

- **WHEN** the user taps **I want to invite a participant** on Major change
- **THEN** a dialog explains termination is required
- **AND** the user can open the FAQ section describing why

---

### Requirement: Agreement overlap gate — voluntary withdrawal exception

The **Agreement period overlap gate** remains unchanged (≥ 2 shared calendar days block **send** / **final accept**). An **exception** applies when accepting a received offer on plan **B** that overlaps an **active** plan **A** on the same device:

- **WHEN** the user has initiated **Major change → voluntary withdrawal** on plan **A** with a **departure date** on or before plan **B**'s proposed `periodStart` (local calendar)
- **THEN** **final accept** on **B** is **not** blocked by overlap with **A**'s blocking interval
- **AND** **send** of unrelated proposals remains blocked until **A**'s blocking interval no longer conflicts or the withdrawal takes effect

#### Scenario: Overlap cleared after scheduling departure

- **WHEN** Monica's active plan ends 2026-12-31 and she schedules voluntary withdrawal on 2026-06-01
- **AND** she receives an offer starting 2026-06-01 that would otherwise overlap by ≥ 2 days
- **THEN** she MAY record **final accept** on the new offer

---

### Requirement: Unfinished votes expire after agreement end

From **local midnight on the calendar day after** the active agreement's inclusive `periodEnd`, any **unfinished vote** tied to that plan on a device SHALL be treated as **refused**. The activity / change journal SHALL record **Refused — agreement expired** (localized equivalent of *Refusé par expiration de l'entente*).

Applies at minimum to:

- open housing proposal / amendment revisions awaiting responses,
- pending participation-change votes (except voluntary-withdrawal notify-only rows, which follow their own departure-date rules).

#### Scenario: Open amendment after end date

- **WHEN** the agreement ended on 2026-03-31 local time and a pending amendment still awaits responses on 2026-04-01 00:00 local
- **THEN** the revision is archived as refused-by-agreement-expiration
- **AND** the journal shows the expired-agreement refusal label

---

### Requirement: Housing trial not restarted when any participant consumed trial

A **newly accepted** housing plan SHALL NOT enter a new housing trial when **any** participating installation identity is already marked `trial_consumed` per `free-until-active-plan-use`. The entitlement layer and client import/activation gates SHALL enforce this before treating the plan as trial-eligible.

#### Scenario: Former trial participant joins new plan

- **WHEN** a new housing plan is accepted and at least one roster installation already consumed housing trial
- **THEN** the plan does not receive a fresh trial period

---

### Requirement: Only connected contacts in proposals and active plans

Module co-participants in housing proposals and active plans MUST reference **connected**, relay-reachable contacts only. Stubs, local-only rows, disconnected contacts, or inline temporary participants MUST NOT be accepted when **sending** or **activating** a plan.

#### Scenario: Send blocked for demoted contact

- **WHEN** a draft roster slot references a contact that is not `connected`
- **THEN** **send proposal** is blocked with a localized explanation

---

### Requirement: Contacts in active or vote-pending work cannot be disconnected

A contact referenced on a housing roster MUST NOT be **disconnected** while either:

- the plan has an **in-force** agreement on this device, or
- an **open** proposal, amendment, or participation-change vote involving that contact is pending on this device.

Deletion rules in `contact-privacy-and-deletion` remain unchanged (disconnect first for connected contacts; delete blocked while referenced).

#### Scenario: Disconnect refused during active agreement

- **WHEN** the user attempts to disconnect a contact who is a participant on an active housing agreement
- **THEN** disconnect is refused and the user sees which plan blocks the action
