#!/usr/bin/env python3
"""Deterministic FCM-wake QA relay routing ids (fixed debug X25519 seeds)."""

from __future__ import annotations

import base64
import hashlib
import hmac
import sys

from cryptography.hazmat.primitives import serialization
from cryptography.hazmat.primitives.asymmetric.x25519 import X25519PrivateKey

_STEADY_STATE_INFO = b"compartarenta/relay-routing/v1"
_MONICA_SEED = bytes(range(0x10, 0x10 + 32))
_LOUYS_SEED = bytes(range(0x20, 0x20 + 32))


def _b64url(data: bytes) -> str:
    return base64.urlsafe_b64encode(data).decode().rstrip("=")


def _hkdf_sha256(ikm: bytes, info: bytes, length: int) -> bytes:
    salt = b"\x00" * 32
    prk = hmac.new(salt, ikm, hashlib.sha256).digest()
    out = b""
    block = b""
    counter = 1
    while len(out) < length:
        block = hmac.new(prk, block + info + bytes([counter]), hashlib.sha256).digest()
        out += block
        counter += 1
    return out[:length]


def _x25519_public_from_seed(seed: bytes) -> bytes:
    private = X25519PrivateKey.from_private_bytes(seed)
    return private.public_key().public_bytes(
        encoding=serialization.Encoding.Raw,
        format=serialization.PublicFormat.Raw,
    )


def _steady_state_address(first_pub: bytes, second_pub: bytes) -> bytes:
    return _hkdf_sha256(first_pub + second_pub, _STEADY_STATE_INFO, 16)


def listen_addresses() -> tuple[str, str]:
    monica_pub = _x25519_public_from_seed(_MONICA_SEED)
    louys_pub = _x25519_public_from_seed(_LOUYS_SEED)
    monica_listen = _steady_state_address(monica_pub, louys_pub)
    louys_listen = _steady_state_address(louys_pub, monica_pub)
    return _b64url(monica_listen), _b64url(louys_listen)


def main() -> int:
    if len(sys.argv) != 2 or sys.argv[1] != "listen_addresses":
        print("usage: qa_fcm_wake_relay_routing.py listen_addresses", file=sys.stderr)
        return 2
    monica, louys = listen_addresses()
    print(monica, louys)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
