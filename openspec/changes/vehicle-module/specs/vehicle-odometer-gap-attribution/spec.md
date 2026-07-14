## ADDED Requirements

### Requirement: Sessions use start and end meter readings
The app SHOULD prompt users to record a **session start** reading when beginning a vehicle use and a **session end** reading when completing it (see `odometer-logging`). Quick-action and session flows SHOULD make both steps easy; completing only a start reading leaves the session **open** until an end reading is saved.

#### Scenario: Recommended start-then-end flow
- **WHEN** a user begins a vehicle use from a quick action or session entry
- **THEN** the app prompts for a **start** meter reading first
- **WHEN** the user later completes the use
- **THEN** the app prompts for an **end** meter reading on the same session

### Requirement: Positive unlogged gap detected at session start
When the user saves a **session start** reading **greater than** the vehicle's **most recent** stored meter reading (whether that prior reading was a session start, session end, or standalone reading), the system SHALL compute the **gap**:

\[
\text{gap} = \text{startReading} - \text{latestReading}
\]

using the vehicle's odometer unit (km or mi per vehicle settings).

If `gap` is zero, no attribution prompt is required.

#### Scenario: Gap prompt on new session start
- **WHEN** the latest stored reading for a vehicle is 12 400 km
- **AND** the user saves a new session start reading of 12 650 km
- **THEN** the system computes a gap of 250 km
- **THEN** the app prompts for gap attribution before finalizing the session start (or immediately after, in the same flow)

#### Scenario: No gap when readings match
- **WHEN** the latest stored reading is 12 400 km
- **AND** the new session start reading is 12 400 km
- **THEN** no gap attribution prompt is shown

### Requirement: Negative gap handling with photo verification
When a new meter reading is **lower than** the vehicle's latest stored reading, the system SHALL treat this as a **negative gap** (reading decreased). The new reading MUST follow the meter photo rules in `odometer-logging` (photo file required when the value changed; session end always requires a photo). Negative-gap handling relies on those photos for visual verification when a photo file is present.

If the acting user is **not** the Propriétaire, the app SHALL **notify the Propriétaire** so they can visually verify the odometer photos for the new reading and the prior reading. **Current release note (2026-07-14):** Emprunteur→Propriétaire notification for this path is **deferred** to **Emprunteur / `vehicle-sharing-module`** work (not required for owner-module delivery). The notification MUST NOT be sent when the Propriétaire is the acting user (**no self-notification**).

If the acting user **is** the Propriétaire, the app SHALL show a dialog stating the negative gap amount and offering exactly two choices before finalizing the save:

1. **Maintain current reading, investigate later** — persist the new reading with a negative-gap acknowledgment and a **journal entry**; the Propriétaire may correct prior readings or gap records later. **Current release (2026-07-14):** the journal entry alone is **acceptable**; a dedicated in-app or push **reminder** after maintain is **deferred** to a future release.
2. **Cancel current entry** — discard the in-progress reading so the Propriétaire can verify the prior reading and correct it first.

The app MUST NOT provide an in-app contestation workflow; participants resolve discrepancies offline. Only the **Propriétaire** MAY later correct readings or gap attributions.

#### Scenario: Emprunteur enters lower reading
- **WHEN** an Emprunteur saves a session reading lower than the latest stored reading
- **THEN** the reading is saved with a photo file per `odometer-logging` (value changed from baseline)
- **THEN** (when Emprunteur/sharing notification work ships) the Propriétaire is notified to verify the photos for the new and prior readings

#### Scenario: Propriétaire chooses to maintain lower reading
- **WHEN** the Propriétaire saves a reading lower than the latest stored reading
- **THEN** the app shows the negative-gap dialog
- **WHEN** the Propriétaire chooses **Maintain current reading, investigate later**
- **THEN** the new reading is persisted with negative-gap acknowledgment and journal entry
- **THEN** no self-notification is sent
- **THEN** (current release) no dedicated reminder beyond the journal entry is required

#### Scenario: Propriétaire cancels to verify prior reading
- **WHEN** the Propriétaire chooses **Cancel current entry** on the negative-gap dialog
- **THEN** the in-progress reading is not saved
- **THEN** the Propriétaire can open the prior reading to verify its photo and correct if needed

### Requirement: Gap attribution question and choices
For a **positive** gap, the app SHALL ask the user (localized):

- **FR:** « À qui le différentiel de {amount} est-il attribuable ? » (use km, engine hours, or locale-appropriate unit)
- **EN:** « Who is the {amount} difference attributable to? »
- **ES:** equivalent product copy

The user MUST choose exactly one of:

1. **Self** — the acting user
2. **Another participant** — the Propriétaire or an **approved Emprunteur** on that vehicle (when sharing applies)
3. **Unknown** — **I don't know** (`unknown` / **Inconnu** in FR UI)

The choice list SHALL include only participants valid for that vehicle (Propriétaire + active sharing links). It MUST NOT offer arbitrary Contacts who are not on the vehicle.

#### Scenario: Shared vehicle lists Propriétaire and Emprunteurs
- **WHEN** a positive gap is detected on a shared vehicle with Propriétaire A and active Emprunteur B
- **AND** Emprunteur B is logging the session start
- **THEN** attribution choices include B (self), A, and **Unknown** (**Je ne sais pas**)

### Requirement: Unknown gap attribution is valid and persistent
Selecting **Unknown** for a positive gap SHALL produce a **valid, durable** gap record that MAY remain **Unknown** indefinitely. The Propriétaire is encouraged to investigate offline; the app MUST NOT force resolution or expire Unknown attributions.

Unknown-attributed gap amounts MUST NOT be included in distance or usage inputs used to compute an **Emprunteur's owed share** (see `vehicle-sharing-usage-metrics`). In practice, the **Propriétaire bears** the cost share corresponding to Unknown usage until they revise attribution to a named participant.

When **Unknown** is selected, the app SHALL **notify the Propriétaire** so they can investigate — unless the acting user **is** the Propriétaire (**no self-notification**).

#### Scenario: Emprunteur selects Unknown
- **WHEN** Emprunteur B attributes a 250 km positive gap to **Unknown**
- **THEN** the gap is stored with `attributedContactId = unknown`
- **THEN** Propriétaire A is notified of the Unknown gap entry

#### Scenario: Propriétaire selects Unknown on solo vehicle
- **WHEN** Propriétaire A attributes a gap to **Unknown**
- **THEN** the gap is stored as Unknown
- **THEN** no notification is sent (self-action)

#### Scenario: Unknown gap excluded from borrower owed calculation
- **WHEN** an allocation window includes fuel or expense sharing for Emprunteur B
- **AND** a 250 km gap remains attributed to **Unknown** in that window
- **THEN** the 250 km is not counted as B-attributed distance for computing B's owed share
- **THEN** the Propriétaire effectively carries that usage share until attribution is revised

### Requirement: Persist gap attribution on the vehicle record
Each detected **positive** gap SHALL be stored on the **Propriétaire's canonical vehicle record** with at least:

- `latestReadingBeforeGap` (value + timestamp reference)
- `startReadingAfterGap` (the new session start)
- `gapAmount` (derived, positive)
- `attributedContactId` (self, another participant, or unknown)
- `recordedByContactId` (who answered the prompt)
- `recordedAt`

Gap attribution is a **factual input** separate from the session's own \(end - start\) usage for that session.

#### Scenario: Gap stored before session continues
- **WHEN** the user completes gap attribution for a positive gap
- **THEN** the gap record is persisted
- **THEN** the new session start reading remains linked to the opening session

### Requirement: Notify attributed participant when not self
When positive gap attribution selects a participant **other than** the acting user, the app SHALL send an **informational** notification (in-app and/or relay push when available) that `{amount}` of unlogged usage was attributed to them on `{vehicle label}`.

The notification is **informational only**. The app MUST NOT implement dispute, contestation, arbitration, or in-app messaging. If a correction is needed, only the **Propriétaire** MAY revise the stored attribution after offline discussion.

#### Scenario: Emprunteur attributes gap to Propriétaire
- **WHEN** Emprunteur B attributes 250 km to Propriétaire A
- **THEN** A receives an informational notification on their device(s)

#### Scenario: Self attribution sends no notification
- **WHEN** the acting user attributes the gap to **self**
- **THEN** no attribution notification is sent for that gap

### Requirement: Propriétaire may revise gap attribution
The **Propriétaire** of the vehicle SHALL be able to **edit** a stored positive gap attribution (change attributed participant or Unknown) after the fact.

When revision assigns the gap to a **different named participant**, the app MAY send an **informational** notification to that participant. The app MUST NOT reopen or track a formal dispute case.

Only the **Propriétaire** MAY perform such revisions; Emprunteurs MAY NOT override a stored attribution.

#### Scenario: Propriétaire changes attribution after offline discussion
- **WHEN** the Propriétaire changes a gap from **Unknown** to Emprunteur C
- **THEN** the stored record is updated
- **THEN** C MAY receive an informational notification
- **THEN** subsequent borrower owed calculations MAY include that gap distance for C

#### Scenario: Emprunteur cannot revise attribution
- **WHEN** an Emprunteur views a gap they previously attributed
- **THEN** they cannot change the attribution

### Requirement: Gap attribution applies on shared and solo-owned vehicles
Positive gap detection and attribution SHALL run for **any** session start reading on a vehicle, whether or not sharing is active. On solo-owned vehicles with no Emprunteurs, choices MAY be limited to **self** and **Unknown**.

Negative gap handling applies to **any** meter reading save, shared or solo.

#### Scenario: Solo owner with unexplained positive gap
- **WHEN** a Propriétaire with no active Emprunteurs logs a session start above the latest reading
- **THEN** the gap prompt offers **self** and **Unknown** at minimum
