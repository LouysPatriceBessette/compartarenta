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

### Requirement: Each realized expense requires unanimous acceptance

A realized expense SHALL affect **published balances** on a device only after **every** roster participant has **accepted** that expense proposal on their device (or equivalent recorded acceptance synced per participant). Partial acceptance MUST NOT publish the expense to group totals.

#### Scenario: One holdout blocks balance impact

- **WHEN** all but one participant have accepted expense E
- **THEN** published balances on any device still exclude E until the last participant accepts

#### Scenario: Full acceptance publishes

- **WHEN** every participant has accepted E
- **THEN** E is treated as agreed ledger data for monthly summaries and balance views

---

### Requirement: Participants review and accept or reject with justification

When a pending expense is visible to a participant, they SHALL be able to **Accept** or **Reject**. **Reject** MUST require a non-empty **justification** (bounded length) explaining the reason (e.g. missing proof, wrong amount, wrong plan line).

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

When a new realized expense proposal is imported for this user, the client SHALL fire a notification (local; push when configured) that a colocataire submitted an expense requiring review. This is distinct from plan offer notifications and from unanimous activation notifications.

#### Scenario: Review notification opens queue

- **WHEN** the user taps the notification
- **THEN** the app opens the pending review entry for that expense

---

### Requirement: Hub routes to monthly expense summary

The active agreement hub SHALL include **Current month expenses** (localized) listing realized expenses with **published** status whose payment date falls in the current calendar month (per device date semantics). The user SHALL be able to navigate to **previous months** (month picker or list — exact UX deferred; requirement is access to history).

#### Scenario: March view excludes February payments

- **WHEN** the user views March summary on 2026-03-15
- **THEN** only published expenses with payment date in March 2026 appear

---

### Requirement: Hub routes to balances owed between participants

The application SHALL compute **who owes whom** from **published** realized expenses and active plan line split weights, including **reimbursement** and **advance** kinds per entry spec rules. The hub action **Balances owed** opens a summary screen with pairwise or net-settlement presentation (algorithm choice is implementation; MUST be deterministic and documented).

#### Scenario: Published expenses update balances

- **WHEN** a new expense reaches published state
- **THEN** balance totals reflect the split for that payment

---

### Requirement: Budget cap lines trigger confirmation when exceeded

When the linked `PlanLine` has `amountIsBudgetCap = true` and the realized amount for a calendar month exceeds the plan line’s cap for that month (product rule: sum of published realized amounts for that line in the month vs cap), the **submitter’s** client SHALL show a confirmation dialog before propose (carries forward `housing-unified-expense-entry` D.2 intent for in-force use).

#### Scenario: Over-cap submit requires confirm

- **WHEN** the user enters an amount that exceeds the monthly budget cap for that line
- **THEN** the user must confirm before the expense is proposed

---

### Requirement: First realized expense sync starts plan active use for licensing

The first successful **propose** or **import** of a realized expense that participates in licensing metering SHALL mark the housing plan as **actively in use** per `free-until-active-plan-use` (trial start). Plan-only sync without realized expenses MUST NOT trigger this transition.

#### Scenario: First propose starts trial clock

- **WHEN** the group’s first realized expense sync occurs on this device
- **THEN** the plan trial timeline starts per licensing spec

---

### Requirement: Wire protocol kinds are documented client-side

The change SHALL document encrypted steady-state message kinds for at least: `housing_realized_expense_propose`, `housing_realized_expense_accept`, `housing_realized_expense_reject`, and `housing_realized_expense_amend` (if corrections are sent as amendments). Payloads include `packageId`, expense proposal id, plan line id, amounts, payer, dates, kind, attachment metadata hashes, and rejection text. Relay source changes are out of scope unless admission rules require new routing identities.

#### Scenario: Protocol doc lists fields

- **WHEN** an implementer reads `docs/` housing ledger protocol appendix
- **THEN** they find field lists and idempotency expectations for each kind
