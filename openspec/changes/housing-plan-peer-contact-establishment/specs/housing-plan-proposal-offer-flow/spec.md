## MODIFIED Requirements

### Requirement: Plan proposal offers are sent only to connected co-participants

When the plan author sends a **housing expense plan + agreement** proposal, the app SHALL target every **non-author** roster participant whose `Contact` is **connected** (per `contacts-module-integration`). The offer payload SHALL be the same **self-contained** proposal package as defined in `plan-contract-proposal-payload` (including `packageId`, `revisionId`, `contentHash`, embedded `plan` and `contract`, and `participantSnapshots` with `peerPublicMaterialB64`), so peers can render the **preview-equivalent** UI without extra fetches.

#### Scenario: Unknown or non-connected roster slot blocks send
- **WHEN** any roster participant is not a connected contact
- **THEN** the app blocks “send offer” with a clear remediation (open contact picker / complete pairing)
- **THEN** no partial send is performed for that revision

---

## ADDED Requirements

### Requirement: Recipients resolve missing peer contacts via plan-mediated establishment

When a recipient's imported proposal lists co-participants who are not relay-reachable connected contacts locally, the app SHALL block plan response actions until remediation. Remediation SHALL be **Establish contact** per missing peer using `peerPublicMaterialB64` from `participantSnapshots` and the protocol in `contact-plan-mediated-establishment`. Invitation-code create/redeem actions SHALL NOT appear on housing missing-contact surfaces.

#### Scenario: Missing peer blocks accept until established
- **WHEN** Louys has imported Monica's proposal but lacks Roberr as a connected contact
- **THEN** Louys cannot Accept the housing offer until Roberr is connected via plan-mediated establishment or an equivalent connected contact match
- **AND** the missing-contacts hub shows **Establish contact** for Roberr
