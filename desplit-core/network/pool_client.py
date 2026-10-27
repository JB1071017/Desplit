"""
gRPC Client for connecting a local machine into the DeSplit Global Pool.
Profiles local hardware, signs node registration, and streams continuous heartbeats.
"""
from __future__ import annotations

import logging
import platform
import socket
import sys
import threading
import time
from pathlib import Path
from typing import Optional

import grpc

# Add proto directory to path
proto_dir = Path(__file__).parent.parent / "proto"
if str(proto_dir) not in sys.path:
    sys.path.insert(0, str(proto_dir))

import desplit_pb2  # type: ignore
import desplit_pb2_grpc  # type: ignore

try:
    from hardware.profiler import HardwareProfile
    from network.identity import NodeIdentity
    from network.stun_client import NetworkEndpoint
except ImportError:
    from ..hardware.profiler import HardwareProfile
    from .identity import NodeIdentity
    from .stun_client import NetworkEndpoint

logger = logging.getLogger("desplit.network.client")


class PoolClient:
    """Client for registering and maintaining this node inside the global compute pool."""

    def __init__(self, target: str = "127.0.0.1:50051"):
        self.target = target
        self._channel = grpc.insecure_channel(target)
        self._stub = desplit_pb2_grpc.PoolServiceStub(self._channel)
        self._node_id: Optional[str] = None
        self._heartbeat_thread: Optional[threading.Thread] = None
        self._stop_heartbeat = threading.Event()
        self.is_registered = False

    def register(
        self,
        identity: NodeIdentity,
        hardware: HardwareProfile,
        endpoint: NetworkEndpoint,
    ) -> desplit_pb2.RegistrationResponse:
        """Register this machine's CPU and GPUs into the pool."""
        self._node_id = identity.node_id

        # Build GPUSpec protobufs
        pb_gpus = [
            desplit_pb2.GPUSpec(
                name=g.name,
                vendor=g.vendor,
                total_vram_mb=g.total_vram_mb,
                free_vram_mb=g.free_vram_mb,
                compute_capability=g.compute_capability,
                device_index=g.device_index,
                temperature_c=g.temperature_c,
                has_cuda=g.has_cuda,
            )
            for g in hardware.gpus
        ]

        # Build CPUSpec protobuf
        pb_cpu = desplit_pb2.CPUSpec(
            name=hardware.cpu.name,
            architecture=hardware.cpu.architecture,
            physical_cores=hardware.cpu.physical_cores,
            logical_cores=hardware.cpu.logical_cores,
            frequency_mhz=hardware.cpu.frequency_mhz,
            has_avx=hardware.cpu.has_avx,
            has_avx2=hardware.cpu.has_avx2,
            has_avx512=hardware.cpu.has_avx512,
        )

        # Build RAMSpec protobuf
        pb_ram = desplit_pb2.RAMSpec(
            total_ram_mb=hardware.ram.total_ram_mb,
            available_ram_mb=hardware.ram.available_ram_mb,
        )

        # Build ComputeBenchmark protobuf
        pb_bench = desplit_pb2.ComputeBenchmark(
            cpu_gflops=hardware.benchmark.cpu_gflops,
            gpu_gflops=hardware.benchmark.gpu_gflops,
            benchmark_duration_ms=hardware.benchmark.benchmark_duration_ms,
        )

        pb_hw = desplit_pb2.HardwareSpec(
            gpus=pb_gpus,
            cpu=pb_cpu,
            ram=pb_ram,
            benchmark=pb_bench,
            os_name=hardware.os_name,
        )

        pb_ep = desplit_pb2.NodeEndpoint(
            public_ip=endpoint.public_ip,
            public_port=endpoint.public_port,
            local_ip=endpoint.local_ip,
            local_port=endpoint.local_port,
            nat_type=endpoint.nat_type,
        )

        hostname = socket.gethostname()
        node_info = desplit_pb2.NodeInfo(
            node_id=identity.node_id,
            public_key=identity.public_key_hex,
            hostname=hostname,
            endpoint=pb_ep,
            hardware=pb_hw,
            status=desplit_pb2.NODE_STATUS_ONLINE,
            joined_timestamp=int(time.time()),
            last_heartbeat_timestamp=int(time.time()),
        )

        # Sign the node_id and timestamp
        sign_payload = f"{identity.node_id}:{hostname}:{int(time.time())}".encode("utf-8")
        sig = identity.sign(sign_payload)

        req = desplit_pb2.RegistrationRequest(node=node_info, signature=sig)
        resp = self._stub.RegisterNode(req, timeout=10.0)

        if resp.success:
            self.is_registered = True
            logger.info(f"Joined pool {resp.assigned_cluster_id} successfully")
            self._start_heartbeat_loop()

        return resp

    def _start_heartbeat_loop(self, interval_seconds: float = 10.0):
        self._stop_heartbeat.clear()

        def _loop():
            while not self._stop_heartbeat.wait(interval_seconds):
                if not self.is_registered or not self._node_id:
                    break
                try:
                    req = desplit_pb2.HeartbeatRequest(
                        node_id=self._node_id,
                        timestamp=int(time.time()),
                    )
                    self._stub.SendHeartbeat(req, timeout=4.0)
                except Exception as e:
                    logger.debug(f"Heartbeat failed: {e}")

        self._heartbeat_thread = threading.Thread(target=_loop, daemon=True)
        self._heartbeat_thread.start()

    def get_cluster_state(self) -> desplit_pb2.ClusterPoolState:
        """Fetch real-time unified cluster capacity across all connected nodes."""
        req = desplit_pb2.ClusterStateRequest(requester_node_id=self._node_id or "")
        return self._stub.GetClusterState(req, timeout=5.0)

    def unregister(self):
        """Leave the pool gracefully."""
        self._stop_heartbeat.set()
        if self.is_registered and self._node_id:
            try:
                req = desplit_pb2.UnregisterRequest(node_id=self._node_id, reason="User shutdown")
                self._stub.UnregisterNode(req, timeout=3.0)
            except Exception:
                pass
            self.is_registered = False

    def close(self):
        self.unregister()
        self._channel.close()
