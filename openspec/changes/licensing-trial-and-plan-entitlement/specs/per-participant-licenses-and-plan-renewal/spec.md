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

#### Scenario: App stores platform renewal metadata after purchase
- **WHEN** a participant purchases or renews a license via the platform store
- **THEN** the app records the relevant store metadata needed to determine license validity and renewal dates

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

