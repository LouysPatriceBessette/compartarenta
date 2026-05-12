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
| _pending_  | _pending_                                | _pending_           | _pending_   | First deployment will replace this row with real values.     |

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

### Baseline (placeholder)

> Replace this block with the first real audit entry before exposing
> the relay sub-domain to public traffic.

- **Date:** _pending_
- **Operator:** _pending_
- **Image digest:** _pending_
- **Checklist version:** [`relay-audit-checklist.md`](./relay-audit-checklist.md)
  as of _pending commit hash_
- **Summary:** _pending_
- **Findings:** _pending_ (see Findings section)

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
