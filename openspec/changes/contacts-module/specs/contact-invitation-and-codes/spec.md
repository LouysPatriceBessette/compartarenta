## ADDED Requirements

### Requirement: The user generates invitation codes on-device
The app SHALL allow the user to generate an **invitation code** for an outgoing contact connection. The code SHALL be generated entirely on-device. The app SHALL NOT contact any server in order to mint the code itself (the relay is only used during the subsequent handshake, per `contact-handshake-over-relay`).

#### Scenario: Generating a code is fully on-device
- **WHEN** the user taps "Invite a contact" from the Contacts area
- **THEN** the app produces an invitation code immediately, regardless of whether the relay is reachable
- **THEN** no network request to mint the code is made

### Requirement: Invitation codes carry sufficient entropy and a human-checkable checksum
Each invitation code SHALL carry enough entropy to be infeasibly guessable. When rendered as a short human-readable token (for dictation by voice, transcription, etc.), the rendered form SHALL include a built-in checksum so transcription errors are detected before the recipient submits the code.

#### Scenario: Mistyped human-readable code is rejected before relay use
- **WHEN** the recipient enters a human-readable code with a single-character transcription error
- **THEN** the app rejects the code locally based on the checksum
- **THEN** no relay traffic is generated for the mistyped code

### Requirement: Invitation codes are single-use and time-bounded
Each invitation code SHALL be single-use: it embeds a nonce that is consumed by a successful handshake or invalidated when the user revokes the code or the expiry passes. Each invitation code SHALL have an **expiry** chosen by the inviter from a documented set of options (default value SHALL be conservative — short enough to discourage long-term sharing of the code).

#### Scenario: Replay of a used code is rejected
- **WHEN** a code has already completed a successful handshake
- **THEN** any subsequent attempt to use the same code is rejected by the inviter's device
- **THEN** no contact stub is created for the replayed use

#### Scenario: Expired code is rejected
- **WHEN** the recipient enters a code after its expiry
- **THEN** the app rejects the code locally and informs the user that the code is no longer valid

### Requirement: Invitation codes are shared out-of-band by the user
The app SHALL provide UI to share the invitation code through channels the user controls (copy to clipboard, share-sheet to messaging apps, QR rendering, etc.). The app SHALL NOT, on the inviter's behalf, send the invitation code via the relay or to any other user, because no relay relationship exists yet between the two parties at the time of code generation.

#### Scenario: Code is shareable via the device share sheet
- **WHEN** the user generates an invitation code
- **THEN** the app exposes "Share", "Copy", and "Show as QR" options
- **THEN** the relay does not receive the plaintext code, the inviter's identity link, or the recipient's identity link as part of code generation

### Requirement: Invitation codes are revocable
The inviter SHALL be able to **revoke** an outstanding invitation code from the app before it is used. Revocation SHALL invalidate the embedded nonce so any subsequent use of the code is rejected by the inviter's device.

#### Scenario: Revoked code is rejected
- **WHEN** the inviter revokes a code that was already shared but not yet redeemed
- **THEN** any subsequent redemption attempt is rejected locally on the inviter's device
- **THEN** the contact stub (if any was pre-created on the inviter's side) is removed or returned to an inert state

### Requirement: The inviter sees outstanding outgoing invitations
The Contacts area SHALL show the inviter the list of **outstanding outgoing invitations**, with each entry's status (pending, used, expired, revoked). Pending entries SHALL show their expiry time.

#### Scenario: Pending invitations are visible with status
- **WHEN** the inviter opens the Contacts area
- **THEN** the area surfaces all outstanding invitations and their status
- **THEN** revoked or expired invitations can be cleared from view at the user's request

### Requirement: Inviter receives expiry reminders for unconsumed invitations
For each **pending** outgoing invitation this device created, the system SHALL notify the **inviter** via relay-scheduled notifications (domain `contacts_invitation_expiry`) both **before** `expiresAt` and **at** `expiresAt` if the code remains unused. Lead times, reminder kinds (`before_expiry` / `expired`), Settings gating, localized copy, and deep link SHALL follow `scheduling-deadline-and-invitation-reminders` in change `housing-scheduled-payment-reminders`.

Validity presets are the standard invitation durations (3h, 8h, 24h, 48h). Fires are wall-clock offsets from `expiresAt` (not housing payment 14:00 rules). Pending fires SHALL be cancelled when the invitation is used or revoked.

#### Scenario: Soon and at-expiry fires for a 24h invitation
- **WHEN** the inviter creates a pending invitation with 24h validity ending at T
- **THEN** the system schedules a soon reminder at T−2h and an unconsumed-expiration notification at T

#### Scenario: Used invitation does not fire at expiry
- **WHEN** the invitee redeems the code before T
- **THEN** pending `before_expiry` and `expired` fires for that invitation are cancelled

### Requirement: The invitee enters a code via clear UI affordances
The app SHALL provide UI for the invitee to enter or scan an invitation code (paste, scan QR, type with checksum-aware feedback). The flow SHALL preview the contact's information (chosen by the inviter at handshake time) before persisting any connection.

#### Scenario: Invitee previews the contact before connecting
- **WHEN** the invitee submits a valid code and the handshake exchanges identity information per `contact-handshake-over-relay`
- **THEN** the invitee sees the inviter's chosen display name and avatar
- **THEN** the invitee can confirm or cancel before the connected Contact is persisted on their device
