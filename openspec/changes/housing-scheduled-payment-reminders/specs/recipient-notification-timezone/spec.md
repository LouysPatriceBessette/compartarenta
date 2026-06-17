## ADDED Requirements

### Requirement: Relay stores IANA timezone per recipient routing identity

The relay SHALL persist an **IANA time zone id** (e.g. `America/Toronto`) per `recipient_routing_id` in `recipient_notification_timezone`. This value is used solely to compute local **14:00** reminder instants for scheduled notifications.

The relay SHALL NOT store free-text labels, UTC offsets without IANA id, or other user profile fields in this table.

#### Scenario: Timezone row is operational metadata

- **WHEN** an auditor inspects `recipient_notification_timezone`
- **THEN** each row contains only an opaque routing id, an IANA id, and audit timestamps

---

### Requirement: Timezone is registered at unanimous plan activation

When a housing plan revision becomes **unanimously active** (E.1), each roster participant's device SHALL ensure that participant's effective IANA timezone is registered on the relay before housing payment reminder fires are materialized for that participant.

- The client establishing **unanimity** SHALL include its own effective IANA timezone in the same send path as the E.1 schedule reconciliation.
- Every **other** roster participant SHALL upsert their own timezone when they import the activation on their device (first processing of the active plan).

Effective timezone SHALL be resolved from `AppPreferences` (`device` policy → current device IANA id; `explicit` policy → stored `timeZoneId`).

#### Scenario: Unanimity sender registers self timezone with schedule

- **WHEN** participant C's accept completes unanimous activation
- **THEN** C's client upserts C's routing id timezone on the relay in the same flow as `housing_reminder_schedule_upsert`

#### Scenario: Peer registers on activation import

- **WHEN** participant R imports the newly active plan and R's timezone is not yet registered or differs from prefs
- **THEN** R's client upserts R's timezone to the relay

#### Scenario: Fire materialization waits for timezone

- **WHEN** a schedule target exists for recipient R but R has no timezone row yet
- **THEN** the relay does not create pending `fire_at` rows for R until R's timezone is registered

---

### Requirement: Timezone is updated when prefs change during an active plan

When the user changes timezone preferences in Settings (`timeZonePolicy` or `timeZoneId`) and this device has at least one **active** housing agreement, the client SHALL:

1. Upsert the new effective IANA timezone for the local routing id on the relay.
2. Request recomputation of all **pending** housing payment reminder fires for that routing id (before-date and overdue).

#### Scenario: Explicit timezone change reschedules pending fires

- **WHEN** the user sets an explicit IANA timezone in Settings while a housing plan is active
- **THEN** the relay updates the timezone row and recomputes pending `fire_at` values using the tiered 14:00 local rules

#### Scenario: Device timezone policy still resolves at upsert

- **WHEN** `timeZonePolicy` is `device`
- **THEN** the upsert uses the device's current IANA id at registration time

---

### Requirement: Timezone upsert is authenticated to self only

A client MAY upsert the timezone row only for routing identities it authentically holds. It SHALL NOT upsert timezone values for other participants.

#### Scenario: Foreign routing id is rejected

- **WHEN** a client attempts to upsert a timezone for another recipient's routing id
- **THEN** the relay rejects the request
