# Design — plan-mediated peer contact establishment

## Scenario (Monica / Louys / Roberr)

Monica authors a plan with Louys and Roberr as **connected** contacts on her device. She sends the proposal. Louys and Roberr each import it; neither has the other as a local connected contact, but each snapshot includes the other's `peerPublicMaterialB64`.

Neither Louys nor Roberr is an "unknown identity" — only the **relationship** is missing locally.

## Inbound watch list ("notification pool")

After import, for every roster co-participant who is **not** yet relay-reachable locally:

1. Read `displayName`, `avatarId`, and `peerPublicMaterialB64` from `participantSnapshots` (matched to roster slot via existing snapshot mapping).
2. Derive the pairwise steady-state listen address: `steadyStateAddress(selfPub, peerPub)`.
3. Register relay routing (`establishRouting`) between self listen address and peer listen address (same pattern as other steady-state sends).
4. Add the self listen address to steady inbox polling and to `routingWakeRecipientIdentities()` so closed-app push can wake the device.

Remove watch entries when the peer becomes a connected contact or when the open received plan row is deleted (implementation detail; spec requires eventual cleanup).

## Protocol (two messages)

Uses **new** steady-state envelope kinds (names are implementation labels):

| Kind | Direction | Purpose |
|------|-----------|---------|
| `contactEstablishmentRequest` | Requester → Target | Requester commits to adding target; carries requester profile + housing context. |
| `contactEstablishmentResponse` | Target → Requester | Target accepts or refuses; carries target profile on accept. |

Encryption: AEAD under keys derived from the two long-term X25519 keys (same family as other steady-state envelopes — not invitation-nonce handshake keys).

Plaintext fields (minimum):

**Request:** requester `displayName`, `avatarId`, `proposerDisplayName`, optional `receivedPlanId` / `revisionId` for audit.

**Response:** `accepted` boolean; on accept, responder `displayName`, `avatarId`.

## End-to-end sequence

```text
Louys (requester)                         Roberr (target)
      |                                          |
      |  1. Tap "Establish contact"              |
      |  2. POST contactEstablishmentRequest     |
      |----------------------------------------->|
      |     (relay + optional FCM wake)          |
      |                                          | 3. Notification:
      |                                          |    "[Louys] wishes to establish
      |                                          |     contact … proposal from [Monica]"
      |                                          |    [Accept] [Refuse]
      |                                          |
      |                                          | 4. User chooses
      |  5. POST contactEstablishmentResponse    |
      |<-----------------------------------------|
      |     (relay + optional FCM wake)          |
      |                                          |
      | 6a. If accepted: promote both to         | 6a. If accepted: promote locally
      |     connected on Louys                   |
      | 6b. If refused: show "Refused [when]"    | 6b. If refused: no new contact
      |     locally; may retry                   |
```

### Requester acceptance intent

When Louys taps **Establish contact**, he is **deemed to have accepted** adding Roberr on his side (product intent). Technically:

- Louys records an **outbound pending** establishment for that peer public key.
- Louys does **not** promote Roberr to `connected` until Roberr's **accepted** response arrives (required so a refusal does not leave a false connected row on Louys).

### Target decision

Roberr MUST explicitly **Accept** or **Refuse** (no auto-accept on this path).

On **Accept**: Roberr posts response, then promotes Louys locally.

On **Refuse**: Roberr posts response; Louys persists a local **refused at** timestamp for display only; Louys MAY send a new request later.

### Notification to requester (#7 — resolved)

The requester learns the outcome via an encrypted **`contactEstablishmentResponse`** on the relay. When the app polls/decrypts it:

- **Accepted** → promote contact locally; optional local notification per user prefs.
- **Refused** → update missing-contacts row with `Refused [date time]`; optional local notification.

FCM wake payload remains content-free per `closed-app-push-delivery`; wording is built on-device after decrypt.

### Target notification copy (fixed product string)

> **[requester display name]** wishes to establish contact with you, in the context of the housing plan proposal from **[proposer display name]**.

Buttons: **Accept** / **Refuse** (localized).

## Mutual simultaneous requests

If Louys and Roberr each tap **Establish contact** before either responds:

- Each device sends a request and enters outbound-pending state.
- When an inbound **request** arrives while outbound-pending exists for the **same** peer public key, the inbound notification MAY be auto-resolved as mutual intent (both already positive on their side) — implementation MAY skip a second prompt and complete on the first **Accept** or on receipt of the peer's request. Exact UX is implementation-tuned; spec requires **no deadlock** and **connected** outcome when both intended to connect.

## Comparison to invitation-code handshake

| | Invitation code | Plan-mediated establishment |
|--|-----------------|---------------------------|
| Peer identity before message | Unknown | Known (`peerPublicMaterialB64` in proposal) |
| Address bootstrap | Nonce-derived handshake addresses | Pairwise steady-state addresses from long-term keys |
| Target confirmation | Was manual on inviter; product may auto-accept code redemption on inviter side separately | **Explicit Accept/Refuse on target** |
| Housing missing-contacts UI | Create / enter code | **Establish contact** only |

The relay never learns public keys or names; it only sees ciphertext and routing ids.

## Relay changes

**None required** if existing `establishRouting` + envelope POST + inbox poll + push wake suffice. Re-assess during implementation per `relay-changes-minimize`.
