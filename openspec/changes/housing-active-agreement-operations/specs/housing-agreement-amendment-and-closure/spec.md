## ADDED Requirements

### Requirement: Active plan is viewable read-only from the hub

The hub action **View current plan** SHALL open a read-only presentation of the **active revision** snapshot: plan lines, splits, agreement period, and contract rules. The user MUST NOT edit fields on this screen; edits route to **Request plan modification**.

#### Scenario: Read-only blocks inline edit

- **WHEN** the user opens view current plan
- **THEN** no save action mutates plan lines without entering amendment flow

---

### Requirement: Plan modifications are one change per unanimous proposal

Each **plan modification** while the agreement is active SHALL change **at most one** logical aspect per proposal revision, sent through the existing housing **offer / renegotiation** machinery (`housing-plan-proposal-offer-flow`, `contract-unanimous-renegotiation`). Bundling unrelated edits in one revision MUST NOT be allowed on the amendment entry path.

Allowed modification **types** (each is one proposal):

| Type | Description |
|------|-------------|
| `line_amount` | Change price / amount of one plan line |
| `line_recurrence` | Change recurrence spec of one plan line |
| `line_payer` | Change payment responsible participant for one plan line |
| `line_add` | Add one new plan line |
| `line_remove` | Retire one plan line (existing realized expenses remain) |
| `agreement_end` | Change agreement end date (including **extension**) |
| `rule_change` | Add, remove, or edit one agreement rule clause |

Changing the **agreement start date** is not part of the normal in-force amendment picker once the agreement has produced published realized-expense history.

#### Scenario: User changes one line amount

- **WHEN** the user requests modification type `line_amount` for line L
- **THEN** the drafted proposal contains only that change plus required metadata

#### Scenario: Extension is an agreement_end modification

- **WHEN** the user extends the lease end date
- **THEN** the proposal type is `agreement_end`, not a new `packageId`

#### Scenario: Agreement start date becomes immutable after first published expense

- **WHEN** at least one realized expense has reached unanimous published state for the active agreement
- **THEN** the user cannot modify the agreement start date through in-force amendment flow

---

### Requirement: Roster changes require ending the agreement and starting a new one

The following MUST NOT be offered as in-force amendment types:

- Adding a participant to the roster,
- Removing a participant (whether unanimous or not),
- Replacing one participant with another.

These require **ending** the current agreement (per product closure rules) and creating a **new** proposal package (new negotiation cycle). The new plan MAY **fork** from the active snapshot to avoid manual re-entry (`housing-plan-proposal-offer-flow` fork lineage).

#### Scenario: Add roommate blocked in amendment wizard

- **WHEN** the user attempts to add a participant from amendment entry
- **THEN** the app directs them to end agreement and start a new plan

---

### Requirement: Hub exposes request plan modification

**Request plan modification** SHALL open a type picker (table above), then the appropriate editor (often reusing `ExpensePlanLineForm` in amendment scope for line types), then the standard send / unanimous response flow.

#### Scenario: Amendment uses same Accept Negotiate Refuse rules

- **WHEN** an amendment proposal is sent
- **THEN** parallel response and invalidation rules match `housing-plan-proposal-offer-flow`

---

### Requirement: Agreement end and renewal

When the agreement **period ends** (calendar end reached or explicit closure action — exact closure UX may be a follow-up), the active revision ceases to accept new realized expenses. Starting a new term SHALL use a **new** unanimous proposal; the author MAY **fork** the ended plan’s active revision as the starting draft.

#### Scenario: Expired agreement blocks new realized expenses

- **WHEN** today is after `periodEnd` and no extension revision is active
- **THEN** **Enter an expense** is disabled or routes to “start new agreement”

#### Scenario: Fork after year completed

- **WHEN** the group completes a one-year agreement and starts a new year
- **THEN** they fork the prior active plan into a new draft package instead of retyping all lines

---

### Requirement: Amendment revisions are part of the same agreement export scope

All accepted amendment revisions under one `packageId` during one continuous agreement SHALL be included in agreement export scope per `housing-agreement-data-portability` (same entente, revision chain).

#### Scenario: Export includes mid-year price change

- **WHEN** the user exports after an accepted `line_amount` amendment
- **THEN** the bundle includes both the original and amended revision metadata
