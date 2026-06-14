# Tasks — housing plan peer contact establishment

**Status:** Spec-only. Do not implement until product review of this change is complete.

## 1. Payload and import

- [ ] 1.1 Extend `exportProposalForParticipant` to include `peerPublicMaterialB64` in each `participantSnapshots` entry (connected contacts only).
- [ ] 1.2 Persist snapshot keys on received plan import; map to local roster slots (existing snapshot mapping).
- [ ] 1.3 On import, build/update inbound establishment watch list per missing peer; register routing + poll + push.

## 2. Protocol

- [ ] 2.1 Add envelope kinds `contactEstablishmentRequest` / `contactEstablishmentResponse` in `envelopes.dart` with steady-state encryption.
- [ ] 2.2 Implement send request (requester) and send response (target) in `HandshakeOrchestrator` or dedicated service.
- [ ] 2.3 Handle inbound request (target UI + Accept/Refuse) and inbound response (requester promote or refusal timestamp).
- [ ] 2.4 Wire closed-app push wake for both kinds on watch-list addresses.

## 3. UI

- [ ] 3.1 Replace invitation-code buttons on `HousingPlanMissingContactsScreen` with **Establish contact** per missing row.
- [ ] 3.2 Show outbound-pending and **Refused [datetime]** states on requester rows.
- [ ] 3.3 Use notification copy: "[requester] wishes to establish contact … proposal from [proposer]" + Accept/Refuse.
- [ ] 3.4 Ensure `housing_invite_proposal_screen` and `housing_amendment_detail_screen` use the same hub (no regression).

## 4. Tests

- [ ] 4.1 Unit tests: snapshot export includes keys; watch list on import; request/accept promotes both sides; refuse shows timestamp.
- [ ] 4.2 Integration test: Monica → Louys + Roberr scenario with plan-mediated establishment (fake relay).

## 5. Docs / l10n

- [ ] 5.1 ARB strings for Establish contact, notification body, Refused label, pending state.
- [ ] 5.2 Update `docs/contacts-module-integration.md` (if present) to describe plan-mediated path vs invitation codes.

## 6. Spec alignment

- [ ] 6.1 Remove or update any task/docs that still say housing missing contacts use invitation codes (`housing-plan-proposal-offer-and-responses/tasks.md` item 1.24 area cross-refs).
