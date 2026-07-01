## ADDED Requirements

This capability is the **single source of truth** for how **Propriétaire** vs **Emprunteur** usage paths relate to **vehicle ownership**, **local storage**, and **relay sync**. Other vehicle specs MUST NOT contradict it.

### Requirement: Local participant identity

A **local participant** is the human using **one app installation**, identified at onboarding (display name and cryptographic identity on that device). Specifications call this person the **local user** or **self** on that installation.

Each real-world participant in a sharing relationship is a **different local participant** on a **different installation** (e.g., Monica on web, Louys on Android). They are connected as **Contacts**; they are not the same local user replicated across devices.

#### Scenario: Three QA personas are three installations
- **WHEN** Monica, Louys, and Roberr each run the app on their respective machines
- **THEN** each has their own local participant identity and their own on-device database
- **THEN** vehicle sharing between them is a **multi-installation** problem, not a single-device simulation

### Requirement: One local database per installation — all vehicle roles

Each app installation SHALL persist **all** vehicle-module data in **one** on-device database (Drift or equivalent), including:

- owned vehicles and owner-path facts (uses, fuel, maintenance, violations),
- sharing links and pending offers,
- accessible (shared) vehicles and borrower-path facts awaiting or after relay delivery.

Role separation MUST NOT be implemented by splitting vehicle data into separate databases, separate stores, or separate apps on the same installation.

#### Scenario: Owner and borrower rows coexist locally
- **WHEN** local user A owns vehicle V and also has an active Emprunteur link on vehicle W owned by participant C (another installation)
- **THEN** records for V and W MAY both exist in A's single local database
- **THEN** the app distinguishes usage by **active role** and **who owns the vehicle**, not by database partition

### Requirement: Active usage role is determined by navigation — not by vehicle module license alone

The app SHALL derive the **active usage role** from **how the user entered** the quick-action or session form:

| Entry path | Active role | Applies to |
| --- | --- | --- |
| **Vehicle** module hub or routes under `/vehicle/…` on an **owned** vehicle | **Propriétaire (owner path)** | Vehicles whose fixed owner is the local user on this installation |
| **Vehicle sharing** hub or routes under `/vehicle-sharing/…` | **Emprunteur (borrower path)** | Vehicles whose fixed owner is **another** participant (another installation) |

The same physical form components MAY be reused; the navigation context MUST be carried explicitly (e.g., `VehicleUsageContext`) for the whole save flow.

#### Scenario: Same form, different role
- **WHEN** the user opens an odometer form from **Vehicle** on their own car
- **THEN** the active role is **owner path** and owner persistence rules apply
- **WHEN** the same user later opens an odometer form from **Vehicle sharing** on C's car
- **THEN** the active role is **borrower path** and forward-to-Propriétaire / relay rules apply
- **THEN** the two submissions are not interchangeable merely because the same human typed both

### Requirement: Local user MUST NOT borrow a vehicle they own — no exceptions

On a given installation, the local user MUST NOT act as **Emprunteur** on any vehicle whose **fixed owner** is that same local user.

This prohibition is **absolute**:

- in production,
- in debug builds,
- in **QA seeds**,
- in **Maestro E2E** scenarios,
- via manual deep links or API calls.

The product MUST NOT offer a "simulate both roles on the same owned vehicle" mode.

#### Scenario: Own car never appears as Emprunteur accessible vehicle
- **WHEN** the local user opens **Vehicle sharing → Accessible vehicles**
- **THEN** none of the vehicles listed under **My vehicles** on the **Vehicle** hub appear there as Emprunteur entries

#### Scenario: Borrower path blocked on own vehicle
- **WHEN** the user reaches a borrower-path odometer or fuel form for a vehicle whose owner is the local user (including forged route or test harness)
- **THEN** the app refuses to save and shows a clear message to use the **Vehicle** module instead
- **THEN** no usage fact is recorded on the borrower path for that vehicle

#### Scenario: QA seed cannot create self-borrow
- **WHEN** a developer or automated test seeds vehicle data
- **THEN** the seed MUST NOT create a state where the local user is both fixed owner and active Emprunteur on the same `vehicleId`
- **THEN** Maestro flows that exercise Emprunteur paths MUST use vehicles whose owner is another installation (once relay fixtures exist), not self-owned vehicles

### Requirement: Same local user MAY own one vehicle and borrow another

On **one** installation, the same local user MAY simultaneously:

- use the **owner path** on vehicles they own, and
- use the **borrower path** on **accessible** vehicles owned by **other** participants.

#### Scenario: Owner who also borrows elsewhere
- **WHEN** A owns car V on A's phone and has an active Emprunteur link on C's car W (C is another installation)
- **THEN** A records owner uses on V through the **Vehicle** hub
- **THEN** A records Emprunteur uses on W through the **Vehicle sharing** hub
- **THEN** both activities use A's **same** local database without violating the self-borrow prohibition

### Requirement: Accessible vehicles come from other installations — relay required

A vehicle listed as **accessible** to the local user as **Emprunteur** MUST be a vehicle whose **fixed owner** is a participant on **another app installation**, made known through **connected Contacts** and **relay sync** (see `privacy-first-sync-architecture`).

The following statement is **false** as a product description and MUST NOT appear in specs, tasks, or implementation notes as the target architecture:

> "Vehicle sharing is complete in one local database without relay."

**Owner-only** use of owned vehicles does not require relay. **Cross-participant** sharing (offer, accept, borrower usage reaching the Propriétaire's canonical record) **does** require relay between installations.

#### Scenario: No relay means no legitimate accessible vehicles
- **WHEN** the local user has only self-owned vehicles in the database and no synced sharing payloads from other installations
- **THEN** **Accessible vehicles** (Emprunteur list) is empty
- **THEN** this is expected behavior, not a missing seed bug

#### Scenario: Borrower fact reaches owner's canonical record
- **WHEN** Emprunteur B on installation B saves a use session on A's shared vehicle
- **THEN** the fact MUST be transmitted to installation A so it joins the **Propriétaire's canonical vehicle record** per `vehicle-sharing-usage-logging`
- **THEN** B's local row (if any) is not a substitute for delivery to A without relay

### Requirement: Do not confuse local persistence with cross-installation completeness

On the Emprunteur device, the app MAY write borrower-path facts into the **local** database first (queue, optimistic UI). That local write does **not** mean sharing is "local-only" or "relay-optional": cross-installation delivery to the Propriétaire's canonical record remains mandatory for the product behavior.

#### Scenario: Offline queue is not "no relay"
- **WHEN** B submits a borrower-path fuel purchase while offline
- **THEN** the app MAY persist a pending outbound fact locally
- **THEN** the product still requires relay delivery to A when connectivity returns; offline queue is not an alternate architecture without relay
