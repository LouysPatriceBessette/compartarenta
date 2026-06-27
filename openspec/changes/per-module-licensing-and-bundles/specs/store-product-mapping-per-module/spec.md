## ADDED Requirements

### Requirement: Each module maps to its own Apple subscription group
On the Apple App Store, each module SHALL be sold as a subscription in **its own subscription group**, separate from any other module's group. This isolation ensures that purchasing or upgrading within one module's group does not auto-terminate a subscription belonging to a different module (Apple enforces "one active subscription per group at a time").

#### Scenario: Buying vehicle-sharing does not cancel housing or vehicle on Apple
- **WHEN** a user with active `housing` and `vehicle` subscriptions purchases `vehicle-sharing` on iOS
- **THEN** the existing subscriptions remain active
- **THEN** the user may use borrower features per `module-subscription-dependencies`

#### Scenario: Buying vehicle does not cancel housing on Apple
- **WHEN** a user with an active `housing` subscription purchases a `vehicle` subscription on iOS
- **THEN** the `housing` subscription remains active and unmodified
- **THEN** the user now has two simultaneously-active subscriptions (one per module's group)

### Requirement: Each module maps to its own Google Play subscription product
On Google Play, each module SHALL be sold as **its own subscription product**, separate from other modules' products. A module's product MAY expose multiple **base plans** (e.g., monthly, prepaid, annual) and MAY expose **offers** as supported by Play Billing; these intra-product variations belong to that module and SHALL NOT bundle entitlement for any other module.

#### Scenario: Switching base plans within housing does not affect vehicle
- **WHEN** a user changes their `housing` base plan from monthly to annual on Google Play
- **THEN** the user's `vehicle` subscription (if any) is not affected
- **THEN** the `housing` effective entitlement remains continuous across the base plan change

### Requirement: Apple subscription group layout is documented and immutable per module
The mapping of module → Apple subscription group SHALL be documented in repository documentation (e.g., a store-mapping reference document) and SHALL NOT be changed after a module ships to production. Subscription identifiers (productID) and group identifiers SHALL also be documented for audit and support.

#### Scenario: Group layout is reviewable in the public repo
- **WHEN** an external reviewer wants to verify module-to-group mapping for Apple
- **THEN** the repository documentation lists each module, its Apple subscription group identifier, and its product identifiers

### Requirement: Google Play product layout is documented per module
The mapping of module → Google Play subscription product (and its allowed base plans / offers) SHALL be documented in repository documentation. Product identifiers (`productId`) SHALL be listed for audit and support, including which base plans are considered canonical for cross-platform parity.

#### Scenario: Play product layout is reviewable in the public repo
- **WHEN** an external reviewer wants to verify module-to-product mapping for Google Play
- **THEN** the repository documentation lists each module, its Play subscription product identifier, and its canonical base plans

### Requirement: Receipt validation evaluates module entitlement using store-provided metadata
The app SHALL determine each module's effective entitlement from the platform-provided receipt / purchase metadata for that module's product (and any bundle product per `bundle-product-mapping`). The metadata captured SHALL be sufficient to:
- verify entitlement on-device (best-effort) and/or via the minimal entitlement server allowed by `subscription-entitlement-minimal-server-state`,
- correlate renewals with the original purchase,
- and explain the current state to the user (e.g., expiration date, trial vs paid).

This requirement extends — at the per-module granularity — the store-metadata capture rules already specified in `per-participant-licenses-and-plan-renewal` for the housing module.

#### Scenario: Receipt metadata captured per module on Apple
- **WHEN** a participant purchases or renews a module subscription on Apple
- **THEN** the app records, per module, at minimum: transaction identifier, original transaction identifier, productID, purchase date, and expiration date when applicable

#### Scenario: Receipt metadata captured per module on Google Play
- **WHEN** a participant purchases or renews a module subscription on Google Play
- **THEN** the app records, per module, at minimum: purchase token, orderId when available, subscription expiration time, auto-renewing status, and acknowledgement state where applicable

### Requirement: Apple per-module subscriptions never co-exist in the same group
The product SHALL NOT place two different modules' subscriptions into the same Apple subscription group, because Apple's "one active per group at a time" rule would force users to choose between modules.

#### Scenario: Subscription group reuse is rejected
- **WHEN** the team plans store-mapping changes
- **THEN** an existing subscription group is never reassigned to a different module
- **THEN** introducing a new module always creates a new subscription group on Apple

### Requirement: Subscription group / product identifiers are stable for the life of a module
Once a module ships to production, the Apple subscription group identifier and the Google Play subscription product identifier mapped to that module SHALL remain stable for the life of the module.

#### Scenario: Identifiers are not renamed after launch
- **WHEN** a module is in production and its store products have been purchased by users
- **THEN** the team does not rename or migrate those identifiers; new variants are added as new base plans, offers, or new products that the module may reference, but the original identifiers remain
