## ADDED Requirements

### Requirement: License is individual per participant
The usage license SHALL be individual: each participant linked to a plan SHALL maintain an active paid license for full plan operation.

#### Scenario: Each participant must purchase
- **WHEN** a plan is operating in paid mode
- **THEN** each linked participant has an active license status for that plan context (or a product-defined equivalent mapping)

### Requirement: Participants are collectively responsible for plan licensing coverage
The product SHALL treat participants as collectively responsible for ensuring all required licenses for a plan are paid so the plan can operate.

#### Scenario: Missing one license blocks plan operation
- **WHEN** at least one required participant license is unpaid
- **THEN** the plan is not considered fully entitled for operation (grace/read-only rules apply elsewhere)

### Requirement: Monthly renewal aligns to a shared plan renewal date
Once all required licenses linked to a plan are paid, the plan SHALL establish a shared monthly renewal date. All participants linked to that plan SHALL renew on the same date (even though the licenses are individual).

#### Scenario: Plan becomes fully paid and sets shared renewal date
- **WHEN** the final missing participant license is successfully paid for a plan
- **THEN** the app sets a plan-level renewal anchor date and reflects it consistently for all participants

### Requirement: License status is derived from store-provided purchase and renewal data
The system MUST derive (or verify) a participant’s license status using purchase and renewal information returned by the platform stores (Apple App Store / Google Play).

The system MUST persist enough store metadata to:
- verify entitlement on-device (best-effort) and/or on a minimal entitlement server,
- correlate renewals to the original purchase,
- and explain the current license state to the user (e.g., expiration date).

A participant license SHALL be considered valid whenever the platform store reports an active entitlement for the applicable product, including standard purchase, offer-code redemption, promo-code redemption, or other store-supported promotional acquisition.

#### Scenario: App stores platform renewal metadata after purchase
- **WHEN** a participant purchases or renews a license via the platform store
- **THEN** the app records the relevant store metadata needed to determine license validity and renewal dates

#### Scenario: Promotional store entitlement counts as a valid license
- **WHEN** a participant redeems a store-supported offer code, promo code, or similar promotional entitlement for the housing license product
- **THEN** the resulting active store entitlement is treated as a valid housing license without a separate app-side special case

### Requirement: Apple subscription metadata captured for licensing
For Apple-managed purchases, the system MUST capture identifiers and timestamps sufficient to track renewals and expiry, including at minimum:
- transaction identifier (e.g., StoreKit `Transaction.id`)
- original transaction identifier (e.g., StoreKit `Transaction.originalID`)
- product identifier (e.g., `productID`)
- purchase date (e.g., `purchaseDate`)
- expiration date (e.g., `expirationDate`) when applicable

This information MAY be sourced from StoreKit transaction properties and/or App Store server notifications payloads (e.g., `signedTransactionInfo` / `signedRenewalInfo`).

#### Scenario: Apple renewal updates expiration
- **WHEN** Apple renews a participant’s subscription
- **THEN** the system receives or queries updated renewal/expiration information
- **THEN** the participant license status is updated accordingly

### Requirement: Google Play subscription metadata captured for licensing
For Google Play managed purchases, the system MUST capture identifiers and timestamps sufficient to track renewals and expiry, including at minimum:
- purchase token (e.g., BillingClient `Purchase.purchaseToken`)
- order id (e.g., `orderId`) when available
- subscription expiration time (e.g., `expiryTimeMillis` via the Google Play Developer API)
- auto-renewing status (e.g., `autoRenewing`)
- acknowledgement state (e.g., `acknowledgementState`) where applicable

#### Scenario: Google Play renewal updates expiry time
- **WHEN** Google Play renews a participant’s subscription
- **THEN** the system obtains updated expiry/renewal state (via on-device signal or server verification)
- **THEN** the participant license status is updated accordingly

### Requirement: The entitlement service computes plan-level authorization for gated operations
The entitlement service SHALL be able to answer whether a participant installation identity may perform relay-mediated operations for a given accepted plan and module scope.

Relay-facing authorization MAY be enforced using short-lived signed entitlement assertions, online entitlement checks, or a hybrid of both.

#### Scenario: Relay checks whether housing sync is allowed
- **WHEN** the relay receives a gated housing request for accepted plan P from participant installation identity I
- **THEN** it can obtain a documented allow/deny decision derived from the entitlement service without contacting Apple or Google directly

### Requirement: Module-specific entitlements remain compartmentalized
Licensing and entitlement decisions SHALL remain scoped to the relevant module. A valid housing entitlement does not automatically imply entitlement for future unrelated modules, and vice versa.

#### Scenario: Housing entitlement does not imply other module access
- **WHEN** a participant has a valid housing entitlement
- **THEN** the system does not automatically grant access to import or gated synchronization in another module unless that module's entitlement policy also allows it

