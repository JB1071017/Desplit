"""
Cryptographic Node Identity Module for DeSplit.
Generates, stores, and verifies Ed25519 node identities and cryptographic signatures.
Every node in the global pool has a unique, authenticated Node ID.
"""
from __future__ import annotations

import hashlib
import json
import os
from dataclasses import asdict, dataclass
from pathlib import Path
from typing import Optional

from cryptography.hazmat.primitives.asymmetric import ed25519
from cryptography.hazmat.primitives import serialization


@dataclass
class NodeIdentity:
    node_id: str
    public_key_hex: str
    _private_key: ed25519.Ed25519PrivateKey

    def sign(self, message: bytes) -> bytes:
        """Sign a binary payload with the node's private key."""
        return self._private_key.sign(message)

    @staticmethod
    def verify(signature: bytes, message: bytes, public_key_hex: str) -> bool:
        """Verify an Ed25519 signature against a public key."""
        try:
            pub_bytes = bytes.fromhex(public_key_hex)
            pub_key = ed25519.Ed25519PublicKey.from_public_bytes(pub_bytes)
            pub_key.verify(signature, message)
            return True
        except Exception:
            return False

    def to_dict(self) -> dict:
        return {
            "node_id": self.node_id,
            "public_key_hex": self.public_key_hex,
        }


def get_or_create_identity(storage_dir: Optional[Path] = None) -> NodeIdentity:
    """
    Retrieve existing Ed25519 identity from ~/.desplit/identity.json or generate a new one.
    """
    if storage_dir is None:
        storage_dir = Path.home() / ".desplit"

    storage_dir.mkdir(parents=True, exist_ok=True)
    identity_file = storage_dir / "identity.json"

    if identity_file.exists():
        try:
            with open(identity_file, "r") as f:
                data = json.load(f)
            priv_bytes = bytes.fromhex(data["private_key_hex"])
            priv_key = ed25519.Ed25519PrivateKey.from_private_bytes(priv_bytes)
            pub_key = priv_key.public_key()
            pub_bytes = pub_key.public_bytes(
                encoding=serialization.Encoding.Raw,
                format=serialization.PublicFormat.Raw,
            )
            pub_hex = pub_bytes.hex()
            node_id = f"node_{hashlib.sha256(pub_bytes).hexdigest()[:16]}"
            return NodeIdentity(node_id=node_id, public_key_hex=pub_hex, _private_key=priv_key)
        except Exception:
            pass  # regenerate on corruption

    # Generate new Ed25519 keypair
    priv_key = ed25519.Ed25519PrivateKey.generate()
    priv_bytes = priv_key.private_bytes(
        encoding=serialization.Encoding.Raw,
        format=serialization.PrivateFormat.Raw,
        encryption_algorithm=serialization.NoEncryption(),
    )
    pub_key = priv_key.public_key()
    pub_bytes = pub_key.public_bytes(
        encoding=serialization.Encoding.Raw,
        format=serialization.PublicFormat.Raw,
    )
    pub_hex = pub_bytes.hex()
    node_id = f"node_{hashlib.sha256(pub_bytes).hexdigest()[:16]}"

    with open(identity_file, "w") as f:
        json.dump(
            {
                "node_id": node_id,
                "public_key_hex": pub_hex,
                "private_key_hex": priv_bytes.hex(),
            },
            f,
            indent=2,
        )

    return NodeIdentity(node_id=node_id, public_key_hex=pub_hex, _private_key=priv_key)
