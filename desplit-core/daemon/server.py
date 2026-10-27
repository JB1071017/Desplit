"""
DeSplit Local Background Engine Daemon.
Exposes a high-speed local HTTP/REST API on http://127.0.0.1:8240 for the Flutter Desktop UI
and CLI tools to monitor and control local compute resources and global pool membership.
"""
from __future__ import annotations

import json
import logging
import os
import platform
import socket
import sys
import threading
import time
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import urlparse

# Add parent path
core_dir = Path(__file__).parent.parent.resolve()
if str(core_dir) not in sys.path:
    sys.path.insert(0, str(core_dir))

import psutil

from hardware.profiler import HardwareProfile, profile_local_hardware
from network.identity import NodeIdentity, get_or_create_identity
from network.pool_registry import GlobalPoolRegistry
from network.stun_client import NetworkEndpoint, discover_public_endpoint

logging.basicConfig(level=logging.INFO, format="%(asctime)s [%(levelname)s] %(message)s")
logger = logging.getLogger("desplit.daemon")


class DaemonState:
    def __init__(self):
        self.cluster_id = "desplit-global-pool-alpha"
        self.is_online = True
        self.identity: NodeIdentity = get_or_create_identity()
        self.endpoint: NetworkEndpoint = discover_public_endpoint()
        self.hardware: HardwareProfile = profile_local_hardware(run_benchmark=True)
        self.registry: GlobalPoolRegistry = GlobalPoolRegistry(cluster_id=self.cluster_id)

        # Register local machine
        self._register_local()

        # Seed global peer nodes
        self._seed_remote_peers()

    def _register_local(self):
        hostname = socket.gethostname()
        hw_dict = self.hardware.to_dict()
        ep_dict = self.endpoint.to_dict()
        self.registry.register_or_update_node(
            node_id=self.identity.node_id,
            public_key=self.identity.public_key_hex,
            hostname=f"{hostname} (YOU)",
            endpoint=ep_dict,
            hardware=hw_dict,
        )

    def _seed_remote_peers(self):
        # Peer A: Tokyo (2x RTX 3080, 32 CPU Cores, 64GB RAM)
        self.registry.register_or_update_node(
            node_id="node_tokyo_rtx3080",
            public_key="3b81f19639c016e788e0b67576a911a37c95b6c97a55df946e38b307ec531101",
            hostname="Tokyo Hub (Tier 1)",
            endpoint={"public_ip": "133.242.18.91", "public_port": 50051, "local_ip": "192.168.0.14", "local_port": 50051, "nat_type": "FullCone"},
            hardware={
                "gpus": [
                    {"name": "NVIDIA GeForce RTX 3080", "vendor": "NVIDIA", "total_vram_mb": 10240, "free_vram_mb": 9800, "compute_capability": "8.6", "device_index": 0, "temperature_c": 52.0, "has_cuda": True},
                    {"name": "NVIDIA GeForce RTX 3080", "vendor": "NVIDIA", "total_vram_mb": 10240, "free_vram_mb": 9800, "compute_capability": "8.6", "device_index": 1, "temperature_c": 54.0, "has_cuda": True},
                ],
                "cpu": {"name": "AMD Ryzen 9 5950X", "architecture": "x86_64", "physical_cores": 16, "logical_cores": 32, "frequency_mhz": 3400.0, "has_avx": True, "has_avx2": True, "has_avx512": False},
                "ram": {"total_ram_mb": 65536, "available_ram_mb": 58000},
                "benchmark": {"cpu_gflops": 185.0, "gpu_gflops": 59000.0, "benchmark_duration_ms": 12.0},
                "os_name": "Linux Ubuntu 22.04 LTS",
                "total_vram_mb": 20480,
                "free_vram_mb": 19600,
            },
        )

        # Peer B: Berlin (1x RTX 4090, 32 CPU Cores, 64GB RAM)
        self.registry.register_or_update_node(
            node_id="node_berlin_rtx4090",
            public_key="a794e792c90e66c2847a98b48f9801a357f6b6c97a55df946e38b307ec532299",
            hostname="Berlin Hub (EU-Central)",
            endpoint={"public_ip": "188.138.45.102", "public_port": 50051, "local_ip": "10.0.1.22", "local_port": 50051, "nat_type": "Restricted"},
            hardware={
                "gpus": [
                    {"name": "NVIDIA GeForce RTX 4090", "vendor": "NVIDIA", "total_vram_mb": 24576, "free_vram_mb": 24000, "compute_capability": "8.9", "device_index": 0, "temperature_c": 48.0, "has_cuda": True},
                ],
                "cpu": {"name": "Intel Core i9-13900K", "architecture": "x86_64", "physical_cores": 24, "logical_cores": 32, "frequency_mhz": 3000.0, "has_avx": True, "has_avx2": True, "has_avx512": False},
                "ram": {"total_ram_mb": 65536, "available_ram_mb": 61000},
                "benchmark": {"cpu_gflops": 240.0, "gpu_gflops": 82000.0, "benchmark_duration_ms": 9.5},
                "os_name": "Linux Ubuntu 24.04 LTS",
                "total_vram_mb": 24576,
                "free_vram_mb": 24000,
            },
        )

        # Peer C: London (CPU Cluster: 64 Cores, 128GB RAM)
        self.registry.register_or_update_node(
            node_id="node_london_cpu_farm",
            public_key="c102a9817f54b6c97a55df946e38b307ec533311894a794e792c90e66c2847a9",
            hostname="London Farm (CPU Shard)",
            endpoint={"public_ip": "51.140.82.15", "public_port": 50051, "local_ip": "10.2.0.5", "local_port": 50051, "nat_type": "FullCone"},
            hardware={
                "gpus": [],
                "cpu": {"name": "AMD EPYC 7742 64-Core", "architecture": "x86_64", "physical_cores": 64, "logical_cores": 128, "frequency_mhz": 2250.0, "has_avx": True, "has_avx2": True, "has_avx512": True},
                "ram": {"total_ram_mb": 131072, "available_ram_mb": 115000},
                "benchmark": {"cpu_gflops": 820.0, "gpu_gflops": 0.0, "benchmark_duration_ms": 15.0},
                "os_name": "Debian 12 Bookworm",
                "total_vram_mb": 0,
                "free_vram_mb": 0,
            },
        )

    def set_online(self, online: bool):
        self.is_online = online
        if online:
            self._register_local()
        else:
            self.registry.unregister_node(self.identity.node_id)
        logger.info(f"Master Power Switch set to {'ONLINE' if online else 'OFFLINE'}")

    def get_realtime_metrics(self) -> dict:
        v = psutil.virtual_memory()
        cpu_pct = psutil.cpu_percent(interval=0.1)
        freq = psutil.cpu_freq()
        cpu_freq_ghz = round((freq.current or 2000.0) / 1000.0, 2) if freq else 2.1

        used_ram_gb = round((v.total - v.available) / (1024**3), 1)
        total_ram_gb = round(v.total / (1024**3), 1)

        gpus_data = []
        for g in self.hardware.gpus:
            gpus_data.append(
                {
                    "name": g.name,
                    "vendor": g.vendor,
                    "total_vram_mb": g.total_vram_mb,
                    "free_vram_mb": g.free_vram_mb,
                    "used_vram_gb": round((g.total_vram_mb - g.free_vram_mb) / 1024, 2),
                    "total_vram_gb": round(g.total_vram_mb / 1024, 2),
                    "temperature_c": g.temperature_c,
                }
            )

        return {
            "cpu_percent": cpu_pct,
            "cpu_frequency_ghz": cpu_freq_ghz,
            "cpu_cores_physical": self.hardware.cpu.physical_cores,
            "cpu_cores_logical": self.hardware.cpu.logical_cores,
            "cpu_name": self.hardware.cpu.name,
            "ram_used_gb": used_ram_gb,
            "ram_total_gb": total_ram_gb,
            "ram_percent": v.percent,
            "gpus": gpus_data,
            "benchmark_cpu_gflops": self.hardware.benchmark.cpu_gflops,
            "benchmark_gpu_gflops": self.hardware.benchmark.gpu_gflops,
        }


# Global singleton daemon state
DAEMON_STATE = DaemonState()


class DeSplitAPIHandler(BaseHTTPRequestHandler):
    def _send_cors_headers(self):
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "Content-Type, Authorization")

    def _send_json(self, data: dict, status_code: int = 200):
        body = json.dumps(data).encode("utf-8")
        self.send_response(status_code)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self._send_cors_headers()
        self.end_headers()
        self.wfile.write(body)

    def do_OPTIONS(self):
        self.send_response(204)
        self._send_cors_headers()
        self.end_headers()

    def do_GET(self):
        parsed = urlparse(self.path)
        path = parsed.path

        if path == "/" or path == "/api/v1/health":
            self._send_json(
                {
                    "status": "ok",
                    "version": "1.0.0",
                    "engine": "DeSplit P2P Engine",
                    "time": time.time(),
                }
            )

        elif path == "/api/v1/status":
            self._send_json(
                {
                    "is_online": DAEMON_STATE.is_online,
                    "node_id": DAEMON_STATE.identity.node_id,
                    "public_key": DAEMON_STATE.identity.public_key_hex,
                    "cluster_id": DAEMON_STATE.cluster_id,
                    "public_ip": DAEMON_STATE.endpoint.public_ip,
                    "public_port": DAEMON_STATE.endpoint.public_port,
                    "local_ip": DAEMON_STATE.endpoint.local_ip,
                    "nat_type": DAEMON_STATE.endpoint.nat_type,
                    "hostname": socket.gethostname(),
                }
            )

        elif path == "/api/v1/hardware":
            metrics = DAEMON_STATE.get_realtime_metrics()
            hw_dict = DAEMON_STATE.hardware.to_dict()
            hw_dict["realtime"] = metrics
            self._send_json(hw_dict)

        elif path == "/api/v1/cluster":
            state = DAEMON_STATE.registry.get_unified_state()
            self._send_json(state.to_dict())

        else:
            self._send_json({"error": "Endpoint not found"}, status_code=404)

    def do_POST(self):
        parsed = urlparse(self.path)
        path = parsed.path

        content_len = int(self.headers.get("Content-Length", 0))
        post_body = self.rfile.read(content_len) if content_len > 0 else b"{}"

        try:
            payload = json.loads(post_body.decode("utf-8")) if post_body else {}
        except Exception:
            payload = {}

        if path == "/api/v1/pool/toggle":
            online = payload.get("online", not DAEMON_STATE.is_online)
            DAEMON_STATE.set_online(bool(online))
            self._send_json(
                {
                    "success": True,
                    "is_online": DAEMON_STATE.is_online,
                    "message": f"Node switched to {'ONLINE' if DAEMON_STATE.is_online else 'OFFLINE'}",
                }
            )
        else:
            self._send_json({"error": "Endpoint not found"}, status_code=404)

    def log_message(self, format, *args):
        # Suppress verbose HTTP access logs to keep terminal tidy
        pass


def run_daemon_server(host: str = "127.0.0.1", port: int = 8240):
    server_address = (host, port)
    httpd = ThreadingHTTPServer(server_address, DeSplitAPIHandler)
    logger.info(f"DeSplit Engine Daemon running on http://{host}:{port}")
    httpd.serve_forever()


if __name__ == "__main__":
    run_daemon_server()
