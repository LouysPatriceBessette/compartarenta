## ADDED Requirements

### Requirement: Combined bundles are modeled as their own subscription product
A combined bundle offer (e.g., "Housing + Vehicle", "Vehicle + Vehicle sharing", "Housing + Vehicle + Vehicle sharing") SHALL be modeled as **its own subscription product** on each platform:
- On Apple, the bundle product SHALL live in its **own dedicated subscription group**, separate from any single-module group.
- On Google Play, the bundle SHALL be its **own subscription product** identifier, separate from any single-module product.

A valid bundle receipt SHALL project effective per-module entitlement for every module the bundle includes (per `module-entitlement-model`).

#### Scenario: Buying the bundle grants all included modules
- **WHEN** a user purchases a valid bundle subscription that lists `housing` and `vehicle` as included modules
- **THEN** the effective entitlement for each included module is at least `active-paid` (subject to bundle validity)

#### Scenario: Vehicle owner bundle grants both vehicle modules
- **WHEN** a user purchases a valid "vehicle + vehicle-sharing" bundle subscription
- **THEN** the effective entitlement for `vehicle` is at least `active-paid` (subject to bundle validity)
- **THEN** the effective entitlement for `vehicle-sharing` is at least `active-paid` (subject to bundle validity)
- **THEN** the user may offer their vehicles for sharing per `module-subscription-dependencies`

#### Scenario: Bundle group is dedicated on Apple
- **WHEN** a bundle product exists on Apple
- **THEN** it belongs to a subscription group that contains only bundle products (no single-module subscription appears in the bundle group)

### Requirement: Existing per-module subscriptions are preserved when a bundle ships
Introducing a new bundle product SHALL NOT modify, rename, migrate, or invalidate any existing per-module subscription on either store. Users keep their per-module subscriptions unless they explicitly switch.

#### Scenario: New bundle does not disturb a current housing subscriber
- **WHEN** a "housing + vehicle" bundle is launched
- **THEN** users with an existing standalone `housing` subscription keep that subscription unchanged
- **THEN** they MAY independently choose to switch to the bundle following platform-supported flows (cancel + buy, or upgrade where the platform allows it)

### Requirement: A documented bundle policy governs which combinations are offered
The team SHALL maintain a documented **bundle policy** stating which module combinations are sold as bundle products. The product SHALL NOT silently offer every possible 2^N combination of modules; only the combinations listed in the policy are valid bundle SKUs.

#### Scenario: Only documented bundle SKUs are sold
- **WHEN** a third module ships in the future
- **THEN** the bundle policy is updated explicitly to list which new combinations (if any) are added as bundle SKUs
- **THEN** no undocumented bundle SKU appears on either store

### Requirement: Store upgrade paths follow platform rules only
The product SHALL offer **`vehicle`** and **`vehicle-sharing`** as separate subscriptions **and** as documented bundle SKUs (e.g., "Vehicle + Vehicle sharing"). Users MAY purchase modules independently or upgrade from `vehicle` to a bundle that adds sharing, using **only** the subscription change mechanisms provided by Apple and Google.

The app MUST NOT impose additional artificial restrictions beyond what the stores already enforce (e.g., the app must not block a store-valid upgrade from standalone `vehicle` to a `vehicle` + `vehicle-sharing` bundle).

#### Scenario: User upgrades from vehicle to vehicle-plus-sharing bundle
- **WHEN** a user with an active standalone `vehicle` subscription initiates a store-supported upgrade to a bundle that includes `vehicle-sharing`
- **THEN** the app surfaces store-native upgrade guidance without extra gating
- **THEN** effective entitlement for both modules follows receipt projection rules after the store confirms the purchase

#### Scenario: User buys modules separately
- **WHEN** a user purchases `vehicle` and later purchases `vehicle-sharing` as separate products
- **THEN** both subscriptions can remain active simultaneously per platform rules
- **THEN** PP/PE features unlock when both are entitled on the Propriétaire device

#### Scenario: Switch guidance is shown
- **WHEN** a user with at least one per-module subscription opens the bundle purchase flow
- **THEN** the app shows a notice explaining that the user's existing per-module subscription does not auto-cancel and how to cancel it (linking to the platform's subscription management UI)

### Requirement: Bundle receipts use the same captured-metadata rules as per-module receipts
The app SHALL capture and persist bundle receipt metadata on the same terms as per-module receipts (per `store-product-mapping-per-module`), sufficient to verify entitlement, correlate renewals, and explain state to the user.

#### Scenario: Bundle receipt metadata is captured on Apple
- **WHEN** a participant purchases or renews a bundle subscription on Apple
- **THEN** the app records the bundle's productID, transaction identifier, original transaction identifier, purchase date, and expiration date when applicable

#### Scenario: Bundle receipt metadata is captured on Google Play
- **WHEN** a participant purchases or renews a bundle subscription on Google Play
- **THEN** the app records the bundle's purchase token, orderId when available, expiration time, auto-renewing status, and acknowledgement state where applicable

### Requirement: A bundle does not retroactively cancel a per-module subscription
Purchasing a bundle on either platform SHALL NOT, by itself, cancel any existing per-module subscription. Cancellation of a per-module subscription remains an explicit user action via the platform's subscription management UI.

#### Scenario: Bundle purchase leaves existing module subs intact
- **WHEN** a user with active `housing` and `vehicle` per-module subscriptions purchases the "housing + vehicle" bundle
- **THEN** all three subscriptions are active until the user explicitly cancels the per-module ones via the platform
- **THEN** the effective entitlement for each module remains favorable (no downgrade) regardless of overlap
