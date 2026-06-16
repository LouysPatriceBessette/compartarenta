# Tasks — housing plan peer contact establishment

**Status:** Implemented (client). Manual QA validated Jun 2026: two participants who were not directly connected were linked via **Contacts manquants** / **Establish contact**, using `peerPublicMaterialB64` from the housing proposal payload. Closed-app push wake (2.4) still depends on `closed-app-push-delivery`.

## 1. Payload and import

- [x] 1.1 Extend `exportProposalForParticipant` to include `peerPublicMaterialB64` in each `participantSnapshots` entry (connected contacts only).
- [x] 1.2 Persist snapshot keys on received plan import; map to local roster slots (existing snapshot mapping).
- [x] 1.3 On import, build/update inbound establishment watch list per missing peer; register routing + poll (+ closed-app push wake → **2.4**).

## 2. Protocol

- [x] 2.1 Add envelope kinds `contactEstablishmentRequest` / `contactEstablishmentResponse` in `envelopes.dart` with steady-state encryption.
- [x] 2.2 Implement send request (requester) and send response (target) in `HandshakeOrchestrator` or dedicated service.
- [x] 2.3 Handle inbound request (target UI + Accept/Refuse) and inbound response (requester promote or refusal timestamp).
- [ ] 2.4 Wire closed-app push wake for both kinds on watch-list addresses.

## 3. UI

- [x] 3.1 Replace invitation-code buttons on `HousingPlanMissingContactsScreen` with **Establish contact** per missing row.
- [x] 3.2 Show outbound-pending and **Refused [datetime]** states on requester rows.
- [x] 3.3 Use notification copy: "[requester] wishes to establish contact … proposal from [proposer]" + Accept/Refuse.
- [x] 3.4 Ensure `housing_invite_proposal_screen` and `housing_amendment_detail_screen` use the same hub (no regression).

## 4. Tests

- [x] 4.1 Unit tests: snapshot export includes keys; watch list on import; request/accept promotes both sides; refuse shows timestamp.
- [x] 4.2 Integration test: Monica → Louys + Roberr scenario with plan-mediated establishment (fake relay).

## 5. Docs / l10n

- [x] 5.1 ARB strings for Establish contact, notification body, Refused label, pending state.
- [x] 5.2 Update `docs/contacts-module-integration.md` (if present) to describe plan-mediated path vs invitation codes.

## 6. Spec alignment

- [x] 6.1 Remove or update any task/docs that still say housing missing contacts use invitation codes (`housing-plan-proposal-offer-and-responses/tasks.md` item 1.24 area cross-refs).

## Manual QA (Jun 2026)

- [x] QA.1 Author sends proposal to A + B while A and B are not connected locally; each side opens **Contacts manquants**, taps **Establish contact**, target accepts — both become connected and can proceed with accept / missing-contact gates cleared.
