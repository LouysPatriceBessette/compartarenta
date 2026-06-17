## ADDED Requirements

### Requirement: Proposal deadline reminders use relay cron instead of local scheduling

The system SHALL **not** rely on on-device local notification scheduling for housing proposal **response deadline** reminders (`housing-plan-proposal-offer-and-responses` task 1.4b). Instead, the relay cron defined in `relay-scheduled-notification-jobs` SHALL fire deadline reminders.

When the author **dispatches** an open `revisionId`, the author's client SHALL register relay fire rows for each recipient (and roles per product table) at lead times before `expiresAt`. When the revision is **invalidated**, **expired**, or the user responds, the registering client SHALL cancel pending fires for that `revisionId`.

#### Scenario: Dispatch registers deadline fires

- **WHEN** the author dispatches a housing proposal revision with `expiresAt` set
- **THEN** the author's client upserts relay scheduled fires for deadline reminders before `expiresAt`

#### Scenario: Response cancels pending deadline fires

- **WHEN** a recipient submits a response for `revisionId` R
- **THEN** pending deadline fires for R are cancelled on the relay

---

### Requirement: Contacts invitation expiry reminders use relay cron instead of local scheduling

The system SHALL **not** rely on on-device local notification scheduling for outgoing **invitation expiry** reminders (`contacts-module` task 3.7). The inviter's client SHALL register relay fire rows when an invitation is **created**, and cancel or reschedule when the invitation is **used**, **revoked**, **expires**, or its validity is **extended**.

#### Scenario: Invitation creation registers expiry fires

- **WHEN** the inviter creates a pending invitation with `expiresAt`
- **THEN** the inviter's client upserts relay scheduled fires for expiry reminders before `expiresAt`

#### Scenario: Revocation cancels expiry fires

- **WHEN** the inviter revokes a pending invitation
- **THEN** all pending expiry fires for that invitation are cancelled on the relay
