# Compartarenta Relay — Audit Log

This file is the public, append-only record of relay deployments and
self-audits. Required by `relay-public-auditability`:

- Each deployed version maps to a tagged release ⇒ "Deployments" table.
- A periodic self-audit (at minimum quarterly) is performed and
  recorded ⇒ "Self-audits" section.
- Audit findings are tracked transparently ⇒ "Findings" section.
- The audit posture applies from day one of public availability ⇒ the
  baseline self-audit below must be dated **on or before** the day the
  relay sub-domain first accepts public traffic.

The placeholder entries below describe the shape of a real entry. They
SHALL be replaced (not deleted) by real entries once the first
deployment happens.

---

## Deployments

| Tag        | Image digest                             | Deployed at         | Operator    | Notes                                                        |
|------------|------------------------------------------|---------------------|-------------|--------------------------------------------------------------|
| v0.1.0 | sha256:1c826875efb8c73a96676d82c0fabcbb3e0f3849167d79bf3c831b773ddc653e | 2026-05-13T21:05Z | operator-on-call | First deployment. |
| v0.2.0 | sha256:b5967deacc70d3b19cd2e31a12f294898a7549951779a8b92ba9a81d63cc010d | 2026-05-19T21:58Z | operator-on-call | Closed-app push delivery (schema v2). Wake dispatch disabled (WAKE_PUSH_DISPATCH_ENABLED=false). Stats cron via daily-stats-append-via-docker.sh. |
| v0.2.1 | sha256:1c826875efb8c73a96676d82c0fabcbb3e0f3849167d79bf3c831b773ddc653e | 2026-05-26T00:23Z | operator-on-call | Raised ENVELOPE_MAX_BYTES to 262144 (256 KiB) for proof-bearing envelopes. Built from commit b69d4bfb2ed0c5b9bb6d5acae04cbdbffebd4567. |

When a new image goes live:

1. Append a new row (do NOT delete the prior one — this is an audit
   log).
2. Set `Tag` to the matching git tag (`v0.x.y`).
3. Set `Image digest` to the immutable container image digest the
   binary was packaged into (`sha256:<…>`).
4. Set `Deployed at` to the ISO-8601 timestamp the deployment went
   live.
5. Set `Operator` to a role identifier (e.g., `operator-on-call`), NOT
   a personal identifier.

---

## Self-audits

Each self-audit runs every item in
[`relay-audit-checklist.md`](./relay-audit-checklist.md) on the live
deployment and records the result here. The cadence is at minimum
quarterly; the first audit (the "baseline") is dated on or before the
first day of public traffic.

### Baseline (v0.1.0)

- **Date:** 2026-05-13T21:05Z
- **Operator:** operator-on-call
- **Image digest:** sha256:1c826875efb8c73a96676d82c0fabcbb3e0f3849167d79bf3c831b773ddc653e
- **Checklist version:** [`relay-audit-checklist.md`](./relay-audit-checklist.md)
  as of 6a2fdc026d472179b50505736f2a5a7c8bfb595a
- **Summary:** Initial deployment of sync.incoherences.org, all checks pass. 
- **Findings:** None. (see Findings section)

### Self-audit — v0.2.0 upgrade

- **Date:** 2026-05-19T21:58Z
- **Operator:** operator-on-call
- **Image digest:** sha256:b5967deacc70d3b19cd2e31a12f294898a7549951779a8b92ba9a81d63cc010d
- **Checklist version:** [`relay-audit-checklist.md`](./relay-audit-checklist.md)
  as of 899e36cb441fef858c78b5b444e191ed5d407a65
- **Summary:** Added a generic closed-app push delivery mechanism, all checks pass. 
- **Findings:** None.

### Self-audit — v0.2.1 envelope size cap update

- **Date:** 2026-05-26T00:23Z
- **Operator:** operator-on-call
- **Image digest:** sha256:1c826875efb8c73a96676d82c0fabcbb3e0f3849167d79bf3c831b773ddc653e
- **Checklist version:** [`relay-audit-checklist.md`](./relay-audit-checklist.md)
  as of b69d4bfb2ed0c5b9bb6d5acae04cbdbffebd4567
- **Summary:** Raised ENVELOPE_MAX_BYTES to 262144 (256 KiB) to allow a single compressed proof image in a relay envelope.
- **Findings:** None.

### Audit cadence

Quarterly minimum. The next self-audit is due no later than 90 days
after the previous one. A missed deadline is itself a finding that
must be recorded below with a documented justification.

---

## Findings

The Findings section is the public tracker for any audit item that did
not match its expected outcome (per `relay-public-auditability` /
"Audit findings are tracked and resolved transparently"). Open
findings remain visible here until the underlying deviation has been
corrected OR explicitly accepted with a documented reason.

| Date       | Auditor / actor   | Checklist item | Observed                                            | Expected                                  | Status   | Resolution / notes                                  |
|------------|-------------------|----------------|-----------------------------------------------------|-------------------------------------------|----------|-----------------------------------------------------|
| _pending_  | _pending_         | A.0            | _placeholder demonstrating the row shape_           | _expected outcome from the checklist_     | accepted | Placeholder. Replace on the first real finding.     |

When opening a finding:

- Set `Date` to the date of the audit run.
- Set `Auditor / actor` to a role identifier (e.g., `operator-on-call`,
  `external-reviewer-2026q3`).
- Reference the checklist item by its letter+number (e.g., `A.2`,
  `C.3`).
- Capture the observed value and the expected value verbatim.
- Set `Status` to `open` initially. Transition to `resolved` when the
  deviation is fixed (link the commit); transition to `accepted` only
  with a documented reason recorded in the `Resolution / notes`
  column.

---

## Configuration drift

If the deployed configuration ever differs from what
[`relay-deployment.md`](./relay-deployment.md) says — TTL values,
image digest, exposed surface, schema — record the drift here as a
finding **before** changing the documentation, per
`relay-public-auditability` /
"Configuration drift between deployed and documented is itself a
finding".
