# Contacts module — Relay payload surface

This document is the canonical inventory of what the **Contacts** module
puts on the wire towards the relay. It is the companion of the
`relay-state-schema-and-retention` spec from the platform side: the
relay only ever sees opaque, encrypted bytes, but auditors need a
precise description of how those bytes are produced and what
plaintext metadata is intentionally *omitted* from every request.

If you change anything that the orchestrator sends to the relay, update
this document in the same change. Reviewers will compare the relay
spec, this document, and the orchestrator implementation as a trio.

## 1. Scope

The Contacts module talks to the relay through five HTTP endpoints:

| Endpoint                              | Direction                | Verb |
| ------------------------------------- | ------------------------ | ---- |
| `POST /v1/handshake/establish`        | client → relay           | POST |
| `POST /v1/envelopes`                  | client → relay           | POST |
| `GET  /v1/inbox/{recipient}`          | relay → client (poll)    | GET  |
| `POST /v1/envelopes/{id}/ack`         | client → relay           | POST |
| `POST /v1/disconnect`                 | client → relay           | POST |

The Contacts code base owns every request body and every payload
serialised inside an envelope. Other modules (housing, car sharing, …)
may reuse the same envelope frame but always go through
`HandshakeOrchestrator` so this document remains exhaustive.

## 2. Routing identifiers — what the relay sees

Every relay request and inbox listing uses **routing identifiers**, not
user identities. A routing identifier is a 32-byte value obtained from
HKDF-SHA-256:

| Use                                  | Inputs                                                    | Info string                          |
| ------------------------------------ | --------------------------------------------------------- | ------------------------------------ |
| Inviter handshake address            | `invitationId ‖ nonce`                                    | `compartarenta/v1/relay/handshake/inviter/address` |
| Invitee handshake address            | `invitationId ‖ nonce`                                    | `compartarenta/v1/relay/handshake/invitee/address` |
| Inviter ephemeral handshake key      | `invitationId ‖ nonce`                                    | `compartarenta/v1/relay/handshake/inviter/key`     |
| Steady-state routing address         | `selfPublicKey` (peer-facing) ‖ `peerPublicKey`           | `compartarenta/v1/relay/steady-state/address`      |

Properties:

- Routing identifiers are **deterministic** but indistinguishable from
  random bytes to anyone who does not hold the invitation code or the
  pair of long-term public keys.
- They are **rotated** after the handshake: handshake addresses are
  decommissioned via `POST /v1/disconnect` as soon as the handshake
  completes (success or rejection), and any further communication uses
  the steady-state address derived from the two long-term keys.
- The relay never learns who hides behind a routing identifier; from
  its point of view, two strangers exchange opaque ciphertext.

## 3. Plaintext fields per endpoint

These are the *only* values that ever leave the device in cleartext.
Each one is either a routing identifier (cf. § 2), a content-free
status code, or an envelope id used to acknowledge delivery. No human
metadata (display names, avatar ids, notes, contact ids) is ever
included as a plaintext field.

### 3.1 `POST /v1/handshake/establish`

```
{ "self_identity": "<routing-id>", "peer_identity": "<routing-id>" }
```

- Both identifiers are routing ids derived in § 2.
- Sent twice per invitation (inviter ↔ invitee), so each side admits
  the other.
- The relay records the routing pair and rate-limits accordingly; it
  does **not** see either user.

### 3.2 `POST /v1/envelopes`

```
{
  "recipient": "<routing-id>",
  "sender":    "<routing-id>",
  "ttl_seconds": <int>,
  "body_b64":  "<base64url of the encrypted frame>"
}
```

- `recipient` and `sender` are routing ids.
- `ttl_seconds` is bounded by the spec (currently ≤ 24 h for hello,
  ≤ 7 days for steady-state envelopes).
- `body_b64` is the AEAD ciphertext + tag (see § 4).
- No other field is sent.

### 3.3 `GET /v1/inbox/{recipient}`

- `{recipient}` is a routing id.
- The response is a list of `(envelope_id, body_b64, sender,
  received_at)` tuples — same shape as § 3.2 plus the relay-issued
  envelope id and a timestamp.

### 3.4 `POST /v1/envelopes/{id}/ack`

- `{id}` is the relay-issued envelope id received via the inbox.
- The body is empty. Acknowledging deletes the envelope from the
  relay-side queue.

### 3.5 `POST /v1/disconnect`

```
{ "self_identity": "<routing-id>", "peer_identity": "<routing-id>" }
```

- Same shape as `establish`.
- Sent right after the handshake to retire the one-shot handshake
  addresses, and again on user-initiated disconnect to retire the
  steady-state address.

## 4. Envelope ciphertext format

Each envelope body is a single ChaCha20-Poly1305 (IETF, 96-bit nonce)
frame:

```
frame = version(1B) || kind(1B) || nonce(12B) || ciphertext || tag(16B)
```

| Field         | Notes                                                                    |
| ------------- | ------------------------------------------------------------------------ |
| `version`     | Currently `0x01`. Bumped only on incompatible frame changes.             |
| `kind`        | `0x01 hello`, `0x02 ack`, `0x03 profile_update`, `0x04 disconnect`.      |
| `nonce`       | 12 random bytes generated per envelope.                                  |
| `ciphertext`  | Encrypted JSON payload (see § 5).                                        |
| `tag`         | Poly1305 authentication tag.                                             |

Keys are derived per envelope kind from a shared secret:

- **Hello / ack**: ECDH between the invitee's long-term private key and
  the inviter's ephemeral handshake public key (or the symmetric
  inverse on the inviter side). HKDF info string distinguishes
  hello-direction from ack-direction.
- **Profile update / disconnect**: ECDH between the two long-term keys.
  HKDF info string `compartarenta/v1/envelope/<kind>`.

The relay cannot decrypt any of this — only the two endpoints can.

## 5. Plaintext inside the envelope (after decryption)

These payloads are visible to the receiving client only.

### 5.1 hello (invitee → inviter)

```json
{
  "v": 1,
  "kind": "hello",
  "self_public_key_b64": "<32 bytes base64url>",
  "self_display_name": "<UTF-8 string, ≤ 64 chars>",
  "self_avatar_id": "<avatar palette key, e.g. 'a01'>"
}
```

- `self_public_key_b64` is the invitee's long-term X25519 public key.
- `self_display_name` and `self_avatar_id` are chosen by the **invitee**
  for themselves; they are not the inviter's view of the invitee. The
  inviter UI surfaces them as-is on the confirmation screen.

### 5.2 ack (inviter → invitee)

```json
{
  "v": 1,
  "kind": "ack",
  "accepted": true,
  "self_public_key_b64": "<32 bytes base64url, only if accepted=true>",
  "self_display_name": "<UTF-8 string, only if accepted=true>",
  "self_avatar_id": "<avatar palette key, only if accepted=true>"
}
```

- `accepted=false` means the inviter rejected the hello. The other
  fields are omitted. The invitee surfaces a localized rejection
  message and drops its stub Contact.
- On `accepted=true`, the invitee promotes its stub to **connected**
  and stores `self_public_key_b64` / `self_display_name` /
  `self_avatar_id` on the local Contact row.

### 5.3 profile_update

```json
{
  "v": 1,
  "kind": "profile_update",
  "self_display_name": "<UTF-8 string>",
  "self_avatar_id": "<avatar palette key>"
}
```

- Broadcast to every connected contact whenever the local user changes
  their display name or avatar.
- The receiver updates the corresponding Contact row in place; no
  state transition.

### 5.4 disconnect

```json
{
  "v": 1,
  "kind": "disconnect"
}
```

- Sent on user-initiated disconnect.
- The receiver demotes the corresponding Contact back to local-only and
  retires the steady-state routing on the relay.

## 6. What is intentionally **not** on the wire

The following are checked in code review and integration tests:

- No HTTP header, query parameter, or request body contains:
  - any `Contact.id`, `Contact.displayName`, `Contact.avatarId`,
    `Contact.notes`;
  - any invitation `shortCode`, deep-link, or QR data;
  - any housing / car-sharing identifier (Contacts module never sends
    those, but other modules must not piggyback on a Contacts request
    either).
- No OS-level address-book permission is requested on Android, iOS,
  macOS, Web, or desktop. The Contacts module is fully self-contained
  in app storage.
- Relay request logging on the device side is structured and excludes
  envelope bodies (only routing ids, kinds, sizes, and timestamps).
