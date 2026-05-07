## 1. Specification and threat model

- [ ] 1.1 Publish `PRIVACY.md` (or `docs/privacy-architecture.md`) describing data classes: on-device, in-transit, server-ephemeral, server-entitlement-only.
- [ ] 1.2 Document relay protocol: endpoints, message envelope, TTL, delivery ack, deletion semantics, and **proposal / accept / reject / amended proposal** lifecycle with identifier rules.
- [ ] 1.3 Document E2EE approach: who generates keys, how recipients obtain keys, rotation, and failure modes.

## 2. Client: local data and boundaries

- [ ] 2.1 Define client-side schema boundaries (what is never exported vs what may be relayed as ciphertext).
- [ ] 2.2 Implement local database with migration strategy and secure storage for keys (platform keystore where available).
- [ ] 2.3 Add in-app or doc links for auditors: where local data lives and how to wipe it (logout / reset).

## 3. Server: entitlement only

- [ ] 3.1 Implement minimal entitlement API (validate subscription, issue short-lived session tokens if needed).
- [ ] 3.2 Ensure no user payload tables for core product data; schema review checklist in CI or PR template.

## 4. Server: relay without durable payload

- [ ] 4.1 Implement relay storage with TTL and explicit delete-on-ack (or delete-on-delivery to all recipients).
- [ ] 4.2 Specify wire protocol for **proposal / accept / reject / amended proposal** messages, including **message id** and **proposal id** rules (aligned with `relay-sync-no-persistence` and `end-to-end-encryption`).
- [ ] 4.3 Add integration tests proving messages are not readable after TTL and not returned after acked delivery.
- [ ] 4.4 Define operational runbook: no payload in logs, log retention, queue monitoring without content.

## 5. Cryptography

- [ ] 5.1 Select algorithms and library versions; document choices and rationale.
- [ ] 5.2 Implement encrypt-on-send / decrypt-on-receive; server must reject plaintext relay uploads if ever introduced by mistake.
- [ ] 5.3 Add test vectors or property tests for serialization and versioned wire format.

## 6. Verifiability and release

- [ ] 6.1 Align store privacy disclosures with this architecture (Data safety / privacy nutrition labels).
- [ ] 6.2 Add client automated tests: delivered-but-not-accepted proposals do not change accepted-ledger balances; reject leaves no accepted trace for that proposal id (per `threat-model-and-verifiability`).
- [ ] 6.3 If server is not fully public, document what is verifiable from client + what requires third-party audit.
