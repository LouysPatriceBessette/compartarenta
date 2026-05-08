## ADDED Requirements

### Requirement: Initial configuration captures a display identity for peer contexts
Before or as part of exiting onboarding, the user SHALL be able to set a **display name** (or equivalent label) used when interacting with peers in shared expense contexts. The app SHALL validate length and disallowed characters to prevent broken sync metadata.

#### Scenario: Display name is required when product mandates it
- **WHEN** the product mandates a display name for peer recognition
- **THEN** the user cannot finish onboarding without providing a non-empty valid display name or an explicitly offered anonymous label option

### Requirement: Monetary presentation defaults are set during initial configuration
The application SHALL establish defaults for how amounts are shown (e.g., **currency** and/or **locale-driven number formatting**) during initial configuration, pre-filled from the device locale where possible, with the user able to change the selection.

#### Scenario: Currency defaults from locale with user override
- **WHEN** the user reaches the monetary preferences step
- **THEN** the app suggests a sensible default currency based on device locale and allows the user to pick a different currency before continuing

### Requirement: Time zone or “today” semantics are consistent for local ledger
The product SHALL define how **dates** for expenses are interpreted (device local time vs explicit time zone). Initial configuration SHALL either set a time zone preference or document that device local time is authoritative, consistently with ledger entry and balance views.

#### Scenario: User is informed how dates work
- **WHEN** the user completes initial configuration
- **THEN** documentation or onboarding copy states whether expense dates follow device local time or a chosen time zone

### Requirement: Optional account or identity linkage is explicit
If the product offers **sign-in** (optional or required), the onboarding or initial configuration flow SHALL state whether local-only mode exists and what features require an account. If sign-in is required for subscription validation, the flow SHALL route the user to sign-in before claiming setup is complete.

#### Scenario: Subscription-gated completion is clear
- **WHEN** an active subscription is required to use ledger features
- **THEN** the user sees where they are in the flow (configure → subscribe → main) and is not dropped into a broken main shell without entitlement

### Requirement: Entry to main shell shows a purposeful empty state
After onboarding and initial configuration, when the user has no accepted expenses yet, the main shell SHALL show a clear **empty state** with primary actions (e.g., “Add expense”, “Invite peer”, “Join shared space”) appropriate to the product.

#### Scenario: First-time main shell is actionable
- **WHEN** the user lands on the main shell with an empty accepted ledger
- **THEN** they see guidance and at least one primary action to create value without hunting through menus

### Requirement: Settings remain editable after onboarding
All values collected during initial configuration (display name, currency, locale-related formats, time zone policy if applicable) SHALL remain editable in a settings area without repeating the full onboarding flow.

#### Scenario: User changes currency after setup
- **WHEN** the user opens settings after completing onboarding
- **THEN** they can change currency or formatting preferences and the app applies them to subsequent displays according to documented rounding rules
