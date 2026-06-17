## ADDED Requirements

### Requirement: Relay enforces entitlement for configured gated housing envelope kinds
When entitlement integration is enabled, the relay SHALL call the entitlement introspection service before persisting envelopes of configured gated kinds (housing proposal, proposal response, realized expense propose/accept/reject).

#### Scenario: Denied introspection rejects envelope
- **WHEN** introspection returns deny for a gated envelope submission
- **THEN** the relay returns HTTP 403 with a documented entitlement refusal code
- **THEN** the envelope is not stored

#### Scenario: Gated kind without gate metadata is rejected
- **WHEN** a gated kind is submitted without required `entitlement_gate` fields
- **THEN** the relay returns HTTP 400 with code `entitlement_gate_required`

### Requirement: Entitlement integration is optional for backward compatibility
When entitlement introspection URL is not configured, the relay SHALL accept envelopes as before without entitlement checks.

#### Scenario: Legacy deployment without entitlement
- **WHEN** `ENTITLEMENT_INTROSPECT_URL` is empty
- **THEN** envelope submission behavior is unchanged from pre-entitlement builds

### Requirement: Relay does not contact platform stores
Entitlement enforcement on the relay SHALL use only the entitlement service (introspection). The relay SHALL NOT call Apple or Google directly.

#### Scenario: Relay refusal uses entitlement service only
- **WHEN** a gated housing envelope is refused
- **THEN** the decision is derived from the entitlement introspection response
