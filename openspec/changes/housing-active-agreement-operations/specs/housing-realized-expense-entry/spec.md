## ADDED Requirements

### Requirement: Realized expense entry is reachable from the active agreement hub

The application SHALL expose **Enter an expense** on the active agreement hub (`HousingActivePlanScreen` per `housing-active-agreement-operations` design) and SHALL navigate to a dedicated full-screen **realized expense entry** flow.

#### Scenario: Hub opens entry form

- **WHEN** the user taps **Enter an expense** on an active agreement
- **THEN** the system opens the realized expense entry screen for that agreement’s `packageId`

---

### Requirement: Realized expenses use a plan line only when the kind needs one

The user SHALL select which **plan line** (`PlanLine` from the active revision) the payment relates to when the realized expense kind is a regular **payment**. A **transfer** MUST NOT require or persist a plan line selection on the active agreement entry path.

#### Scenario: Payment lists only active revision lines

- **WHEN** the entry form opens for a payment
- **THEN** the plan line picker lists lines from the currently active plan revision only

#### Scenario: Payment line required to submit

- **WHEN** the user is entering a payment and no plan line is selected
- **THEN** submit is disabled or rejected with validation messaging

#### Scenario: Transfer omits plan line

- **WHEN** the user switches the realized expense kind to transfer
- **THEN** the plan line control is hidden and no plan line is required to submit

---

### Requirement: Entry captures payment facts distinct from plan structure

The entry form SHALL collect at minimum:

- **Amount** (minor units, same money rules as plan authoring),
- **Payment or transfer date** (calendar date in device-local or configured preference semantics),
- **Payer** (which participant paid the vendor or institution),
- **Expense kind**: `normal` | `transfer` (localized labels such as **Payment** and **Transfer**).

For **transfer**, the user SHALL indicate which participant **received** the amount (beneficiary participant) and MAY add an optional description/comment. Transfer entries SHALL affect participant balances only and SHALL NOT consume a plan line budget total.

Split amounts for a **payment** SHALL be derived from the active plan line’s `PlanRatio` weights at submit time unless the ledger spec defines an override path for corrections.

#### Scenario: Normal utility payment

- **WHEN** the user records a normal expense for electricity plan line L with amount 120.00 paid by participant P on date D
- **THEN** the draft stores line id L, payer P, date D, kind `normal`, and amount in minor units

#### Scenario: Transfer

- **WHEN** the user records that participant B transferred an amount to participant A
- **THEN** the draft stores kind `transfer`, payer B, beneficiary A, the amount, the date, and the optional description without requiring a plan line

---

### Requirement: Proof attachment is optional but strongly encouraged

The form SHALL offer **add proof** (camera, gallery, or document). Proof is **optional** for submit but the UI SHALL use prominent copy encouraging attachment (localized; not blocking validation).

#### Scenario: Submit without proof allowed

- **WHEN** the user completes required fields and taps submit without proof
- **THEN** the expense MAY be proposed to peers without an attachment

#### Scenario: Add proof before submit

- **WHEN** the user attaches a proof file
- **THEN** the draft stores the local proof artifact and the propose step MAY include the encrypted proof bytes needed for peer review surfaces

---

### Requirement: Proof pipeline reduces size before persistence

Before persisting a proof image, the client SHALL offer **crop** (when the source is an image) and SHALL apply **compression** (quality / dimension caps — exact parameters are implementation choices documented in code). The stored artifact MUST be suitable for long-term on-device retention without duplicating full camera originals unless the user opts in.

#### Scenario: Large photo is compressed

- **WHEN** the user picks a multi-megabyte photo
- **THEN** the persisted file is smaller than the original per compression settings

---

### Requirement: Proofs are stored in user-accessible on-device storage

Proof files SHALL be written to a directory policy that allows the user to locate files with the device file manager or platform equivalent (not an opaque app-private-only blob with no export path). The database stores a **path** and **display file name**; export bundles reference the path only (see `housing-agreement-data-portability`).

#### Scenario: Export references path not bytes

- **WHEN** the user exports the agreement bundle
- **THEN** proof entries contain path and file name fields, not embedded image binary

#### Scenario: Peer review can import encrypted proof content

- **WHEN** a realized expense with proof is proposed to peers
- **THEN** the encrypted sync payload MAY include the proof bytes required to recreate a local review copy on the receiving device without changing the export format

---

### Requirement: Missing proof files show the file name, not a technical error

When displaying a past realized expense, if the stored path no longer resolves to a readable file (user moved or deleted it outside the app), the UI SHALL show the **display file name** and neutral explanatory copy. The UI MUST NOT show a raw I/O exception string to the user.

#### Scenario: File moved on disk

- **WHEN** the user opens an accepted expense whose proof path is missing
- **THEN** the UI shows the saved file name and indicates the file is unavailable

---

### Requirement: Entry does not finalize the group ledger alone

Submitting the entry form SHALL create or update a **local draft** and SHALL hand off to the **propose** step defined in `housing-realized-expense-ledger`. Submit MUST NOT mark the expense as unanimously accepted or update published balances without the ledger acceptance flow.

#### Scenario: Submit proposes to peers

- **WHEN** the user submits a complete entry
- **THEN** the client transitions the expense to `proposed` state and initiates sync per the ledger spec

---

### Requirement: Entry form is separate from plan line authoring form

The realized expense entry MUST NOT reuse `ExpensePlanLineForm` as the same widget without a distinct scope: plan lines define structure; realized expenses record events. Shared controls (money input, participant pickers) MAY be reused at the implementation layer.

#### Scenario: Editing plan structure uses amendment flow

- **WHEN** the user wants to change a plan line’s budgeted amount for the future
- **THEN** they use **Request plan modification** (amendment spec), not the realized expense entry form
