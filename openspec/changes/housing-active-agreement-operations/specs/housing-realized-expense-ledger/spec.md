## ADDED Requirements

### Requirement: Realized expenses follow propose-then-accept sync semantics

Creating or importing a peer’s realized expense on a device SHALL follow `data-locality-and-client-storage`: incoming rows are **proposals** until the local user **accepts**. Rejected proposals MUST NOT affect **published balances**.

#### Scenario: Peer expense arrives as pending

- **WHEN** a colocataire proposes a realized expense via encrypted relay
- **THEN** this device stores it as pending review and excludes it from published balance totals

#### Scenario: Local accept promotes to ledger truth

- **WHEN** the user accepts a pending expense on this device
- **THEN** the expense is stored in the accepted ledger slice and included in balance calculations

---

### Requirement: Each realized expense publishes after its required reviewers accept

A realized expense SHALL affect **published balances** on a device only after all participants required by that expense kind have **accepted** the proposal on their device (or equivalent recorded acceptance synced per participant). Partial acceptance MUST NOT publish the expense to group totals.

For a regular **payment**, the required reviewers are the full accepted active roster for that housing plan. For a **transfer**, the required reviewers are only:

- the submitter/payer (auto-accepted when proposed), and
- the beneficiary participant who received the amount.

The system SHALL expose enough non-payload metadata for realized-expense decisions to allow server-side determination of publication eligibility for an expense within the accepted active roster of that housing plan.

#### Scenario: Payment still waits for the last roster participant

- **WHEN** all but one roster participant have accepted payment expense E
- **THEN** published balances on any device still exclude E until the last required participant accepts

#### Scenario: Transfer waits only for beneficiary

- **WHEN** the payer has proposed transfer expense E to beneficiary B
- **THEN** E remains excluded from published balances until B accepts, regardless of other non-impacted roster participants

#### Scenario: Required acceptance publishes

- **WHEN** every participant required for expense E has accepted E
- **THEN** E is treated as agreed ledger data for monthly summaries and balance views

#### Scenario: Entitlement service derives publication eligibility
- **WHEN** the entitlement service has observed `accept` decisions from every installation identity required for expense E
- **THEN** E is considered published for server-governed gating logic without reading business-domain ciphertext

---

### Requirement: Participants review and accept or reject with justification

When a pending expense is visible to a participant and that participant is a required reviewer for the expense kind, they SHALL be able to **Accept** or **Reject**. **Reject** MUST require a non-empty **justification** (bounded length) explaining the reason (e.g. missing proof, wrong amount, wrong plan line).

For a **transfer**, only the beneficiary participant SHALL receive a pending review decision on peer devices. Other non-impacted participants SHALL NOT be asked to decide on the transfer and SHALL only see it in published history after acceptance.

#### Scenario: Reject without text blocked

- **WHEN** the user selects Reject and leaves justification empty
- **THEN** submit is disabled or rejected

#### Scenario: Reject notifies originator

- **WHEN** a participant rejects expense E with justification J
- **THEN** the originator receives the rejection and J through the sync channel and activity surfaces

---

### Requirement: Rejected expenses may be corrected and resubmitted

After rejection, the originator SHALL be able to edit the expense and **resubmit** as a **new proposal** (new stable proposal id). Prior rejected proposal ids remain in audit history. Resubmission MUST NOT silently overwrite peer acceptance of the rejected version.

#### Scenario: Resubmit after missing proof rejection

- **WHEN** the originator adds proof and resubmits
- **THEN** peers see a new pending proposal and must accept again

---

### Requirement: Expense state machine

Each realized expense on a device SHALL be in exactly one primary state among:

- `draft` (local, not yet proposed),
- `proposed` (awaiting peer decisions),
- `accepted` (this user accepted; may still await others for publish),
- `published` (unanimous accept — participates in balances),
- `rejected` (this user or group rejected; not published).

Implementation MAY subdivide `proposed` / `accepted` per participant; user-visible copy MUST distinguish “waiting for you” vs “waiting for others.”

#### Scenario: Draft not visible to peers

- **WHEN** the expense is in `draft`
- **THEN** no relay propose envelope has been sent

---

### Requirement: Notifications when peers submit expenses

When a new realized expense proposal is imported for this user, the client SHALL fire a notification (local; push when configured) only if that user must review the proposal. This is distinct from plan offer notifications and from unanimous activation notifications.

#### Scenario: Review notification opens queue

- **WHEN** the user taps the notification
- **THEN** the app opens the pending review entry for that expense

#### Scenario: Non-impacted transfer participant is not notified

- **WHEN** a transfer proposal is imported on a device belonging to a roster participant who is neither the payer nor the beneficiary
- **THEN** the client stores the proposal without showing a review notification or review action for that participant

---

### Requirement: Hub routes to monthly expense summary

The active agreement hub SHALL include **Current month expenses** (localized) listing realized expenses with **published** status whose payment date falls in the current calendar month (per device date semantics). The user SHALL be able to navigate to **previous months** (month picker or list — exact UX deferred; requirement is access to history).

#### Scenario: March view excludes February payments

- **WHEN** the user views March summary on 2026-03-15
- **THEN** only published expenses with payment date in March 2026 appear

---

### Requirement: Hub routes to balances owed between participants

The application SHALL compute **who owes whom** from **published** realized expenses and active plan line split weights, including **reimbursement**, **advance**, and **transfer** kinds per entry spec rules. The hub action **Balances owed** opens a summary screen that exposes two deterministic views over the same published ledger:

- **Real**: aggregate directed obligations exactly as produced by published expenses and transfers after line-split expansion
- **Optimized**: a deterministic compensated settlement rebuilt from the Real view by netting each participant's incoming and outgoing obligations

The application SHALL assign a stable participant letter and graph position from the accepted active roster order for the plan, and the same roster state SHALL produce the same graph on every device.

#### Scenario: Published expenses update balances

- **WHEN** a new expense reaches published state
- **THEN** balance totals reflect the split for that payment

#### Scenario: Real mode preserves opposite-direction obligations

- **WHEN** participant A owes participant B from one published item and participant B owes participant A from another
- **THEN** the Real mode SHALL display both directed obligations without cancelling them

#### Scenario: Optimized mode compensates through deterministic net settlement

- **WHEN** the same published ledger is viewed in Optimized mode
- **THEN** the application SHALL recompute a deterministic net settlement graph from each participant's incoming and outgoing totals

#### Scenario: Transfers participate in balance reconstruction

- **WHEN** a published transfer and a published shared expense cancel each other
- **THEN** Optimized balances SHALL reduce the pairwise debt accordingly, including to zero when fully offset

---

### Requirement: Budget cap lines trigger confirmation when exceeded

When the linked `PlanLine` has `amountIsBudgetCap = true` and the realized amount for a calendar month exceeds the plan line’s cap for that month (product rule: sum of published realized amounts for that line in the month vs cap), the **submitter’s** client SHALL show a confirmation dialog before propose (carries forward `housing-unified-expense-entry` D.2 intent for in-force use).

#### Scenario: Over-cap submit requires confirm

- **WHEN** the user enters an amount that exceeds the monthly budget cap for that line
- **THEN** the user must confirm before the expense is proposed

---

### Requirement: First realized expense sync starts plan active use for licensing

The first successful **propose** or **import** of a realized expense that participates in licensing metering SHALL mark the housing plan as **actively in use** per `free-until-active-plan-use` (trial start). Plan-only sync without realized expenses MUST NOT trigger this transition.

The canonical trial start is recorded by the entitlement service, not inferred only from local UI state.

#### Scenario: First propose starts trial clock

- **WHEN** the group’s first realized expense sync occurs on this device
- **THEN** the entitlement service starts the plan trial timeline per licensing spec

---

### Requirement: Wire protocol kinds are documented client-side

The change SHALL document encrypted steady-state message kinds for at least: `housing_realized_expense_propose`, `housing_realized_expense_accept`, `housing_realized_expense_reject`, and `housing_realized_expense_amend` (if corrections are sent as amendments). Payloads include `packageId`, expense proposal id, plan line id, amounts, payer, dates, kind, attachment display metadata, proof bytes when proof review is enabled, and rejection text. Relay source changes are out of scope unless admission rules require new routing identities.

The transport documentation SHALL also define the minimal relay-visible metadata required for server-side entitlement gating and unanimous-publication checks, including at minimum `module`, `plan_id`, `expense_id`, `participant_installation_id`, and `decision_kind` where applicable.

#### Scenario: Protocol doc lists fields

- **WHEN** an implementer reads `docs/` housing ledger protocol appendix
- **THEN** they find field lists, relay-visible metadata, and idempotency expectations for each kind
