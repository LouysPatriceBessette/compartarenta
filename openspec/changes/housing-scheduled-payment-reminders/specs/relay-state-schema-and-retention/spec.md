## MODIFIED Requirements

### Requirement: The relay database schema is explicitly enumerated and minimal

The relay database SHALL contain only the following kinds of data, and SHALL NOT contain anything else:

1. **Routing relationships** between connected users (opaque identifiers only, with established-at and status timestamps).
2. **Idempotency entries** (opaque idempotency key, sender opaque identity, created-at, ttl-expires-at).
3. **Undelivered ciphertext envelopes** (envelope id, sender opaque identity, recipient opaque identity, ciphertext blob, created-at, ttl-expires-at, delivered-at — null until delivered).
4. **Operational housekeeping rows** strictly required for the relay to run (e.g., schema version, sweeper checkpoints).
5. **Scheduled notification housekeeping rows** for time-triggered reminders: opaque scope identifiers, recipient routing identifiers, reminder kind enums, monotonic generation counters, scheduling instants (`fire_at`, `due_at`, `bound_at`), and **IANA time zone ids** per recipient (`recipient_notification_timezone`) — all without amounts, titles, or other user-facing plaintext.

#### Scenario: A new table requires a documented purpose

- **WHEN** a future relay change introduces a new database table
- **THEN** the proposed table falls into one of the enumerated categories or is rejected
- **THEN** the documentation of the schema is updated as part of the same change

#### Scenario: Scheduled notification tables fit category five

- **WHEN** `scheduled_notification_targets` and `scheduled_notification_fires` are added
- **THEN** they are documented under category five and contain no forbidden plaintext fields

#### Scenario: Scheduling timestamps are not user payload

- **WHEN** an auditor inspects scheduling columns (`fire_at`, `due_at`, `bound_at`)
- **THEN** they contain only operational instants paired with opaque scope ids
- **THEN** no column contains expense amounts, descriptions, or participant display names
