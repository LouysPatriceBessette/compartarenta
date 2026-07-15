## ADDED Requirements

### Requirement: Sandbox invite does not mint external invitation codes

When `sandboxMode` is true, the Contacts invite entry point SHALL NOT generate, display, or share an external invitation code or QR for human out-of-band redeem. That entry point SHALL instead follow `sandbox-bot-peers` (add next catalog bot, or show the exhausted-catalog dialog).

#### Scenario: Code mint skipped in sandbox
- **WHEN** sandbox mode is active and the user starts Invite someone
- **THEN** no invitation code is minted for external redeem
- **THEN** bot-invite or exhausted-catalog behavior applies instead

### Requirement: Real-mode invitation codes unchanged outside sandbox

When `sandboxMode` is false, existing invitation code generation, entropy, expiry, revoke, and share behaviors SHALL remain unchanged.

#### Scenario: Real mode still generates codes
- **WHEN** sandbox mode is false and the user generates an invitation
- **THEN** an invitation code is produced per existing contact-invitation requirements
