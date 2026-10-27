"""
STUN (Session Traversal Utilities for NAT) and Public Endpoint Discovery for DeSplit.
Determines local IP, external public IP, and port via standard STUN servers.
Allows nodes on different home Wi-Fi and 5G networks to discover their external address.
"""
from __future__ import annotations

import logging
import socket
import struct
from dataclasses import asdict, dataclass
from typing import Optional, Tuple

logger = logging.getLogger("desplit.network.stun")

# Public reliable STUN servers
STUN_SERVERS = [
    ("stun.l.google.com", 19302),
    ("stun1.l.google.com", 19302),
    ("stun.cloudflare.com", 3478),
]


@dataclass
class NetworkEndpoint:
    public_ip: str
    public_port: int
    local_ip: str
    local_port: int
    nat_type: str

    def to_dict(self) -> dict:
        return asdict(self)


def get_local_ip() -> str:
    """Get the primary local LAN IP address of this machine."""
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    try:
        # Does not actually send data over wire
        s.connect(("8.8.8.8", 80))
        local_ip = s.getsockname()[0]
    except Exception:
        local_ip = "127.0.0.1"
    finally:
        s.close()
    return local_ip


def _stun_binding_request(server_host: str, server_port: int, local_port: int = 0) -> Optional[Tuple[str, int]]:
    """
    Perform a classic RFC 5389 STUN Binding Request over UDP.
    Returns (mapped_public_ip, mapped_public_port).
    """
    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    sock.settimeout(2.0)
    try:
        if local_port > 0:
            sock.bind(("", local_port))

        # STUN Binding Request header:
        # Message Type: 0x0001 (Binding Request)
        # Message Length: 0x0000
        # Magic Cookie: 0x2112A442
        # Transaction ID: 12 random bytes (96 bits)
        magic_cookie = 0x2112A442
        trans_id = b"\xa1\xb2\xc3\xd4\xe5\xf6\x07\x18\x29\x3a\x4b\x5c"
        header = struct.pack("!HHI12s", 0x0001, 0, magic_cookie, trans_id)

        sock.sendto(header, (server_host, server_port))
        data, _ = sock.recvfrom(2048)

        if len(data) < 20:
            return None

        msg_type, msg_len, magic = struct.unpack("!HHI", data[:8])
        if msg_type != 0x0101:  # Binding Response
            return None

        # Parse STUN attributes
        offset = 20
        while offset < 20 + msg_len:
            attr_type, attr_len = struct.unpack("!HH", data[offset : offset + 4])
            val_offset = offset + 4

            # XOR-MAPPED-ADDRESS (0x0020)
            if attr_type == 0x0020 and attr_len >= 8:
                _, family, xor_port = struct.unpack("!BBH", data[val_offset : val_offset + 4])
                port = xor_port ^ (magic_cookie >> 16)
                if family == 0x01:  # IPv4
                    xor_ip_int = struct.unpack("!I", data[val_offset + 4 : val_offset + 8])[0]
                    ip_int = xor_ip_int ^ magic_cookie
                    ip = socket.inet_ntoa(struct.pack("!I", ip_int))
                    return ip, port

            # MAPPED-ADDRESS (0x0001)
            elif attr_type == 0x0001 and attr_len >= 8:
                _, family, port = struct.unpack("!BBH", data[val_offset : val_offset + 4])
                if family == 0x01:
                    ip = socket.inet_ntoa(data[val_offset + 4 : val_offset + 8])
                    return ip, port

            offset += 4 + attr_len
            # STUN attributes are padded to 4 bytes
            if attr_len % 4 != 0:
                offset += 4 - (attr_len % 4)

    except Exception as e:
        logger.debug(f"STUN query to {server_host} timed out / failed: {e}")
    finally:
        sock.close()
    return None


def _http_fallback_public_ip() -> Optional[str]:
    """Fallback to HTTPS IP lookup if UDP STUN is blocked."""
    import urllib.request

    urls = ["https://api.ipify.org", "https://icanhazip.com"]
    for url in urls:
        try:
            req = urllib.request.Request(url, headers={"User-Agent": "DeSplit/1.0"})
            with urllib.request.urlopen(req, timeout=2.5) as resp:
                ip = resp.read().decode("utf-8").strip()
                if ip:
                    return ip
        except Exception:
            continue
    return None


def discover_public_endpoint(local_port: int = 50051) -> NetworkEndpoint:
    """
    Discover the public and local network coordinates of this node.
    """
    local_ip = get_local_ip()

    # Try STUN servers
    for host, port in STUN_SERVERS:
        res = _stun_binding_request(host, port, local_port=0)
        if res:
            pub_ip, pub_port = res
            return NetworkEndpoint(
                public_ip=pub_ip,
                public_port=pub_port,
                local_ip=local_ip,
                local_port=local_port,
                nat_type="STUN-Mapped",
            )

    # Fallback to HTTP
    pub_ip = _http_fallback_public_ip() or local_ip
    return NetworkEndpoint(
        public_ip=pub_ip,
        public_port=local_port,
        local_ip=local_ip,
        local_port=local_port,
        nat_type="Fallback-NAT",
    )
