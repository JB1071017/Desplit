"""
gRPC Server implementation for DeSplit Global Pool Service.
Listens for node registrations, heartbeats, and cluster topology inquiries.
Maintains the live consolidated pool of all connected GPUs and CPUs.
"""
from __future__ import annotations

import logging
import sys
import time
from concurrent import futures
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
    from network.pool_registry import GlobalPoolRegistry
except ImportError:
    from .pool_registry import GlobalPoolRegistry

logger = logging.getLogger("desplit.network.server")


def _build_cluster_state_pb(state) -> desplit_pb2.ClusterPoolState:
    """Helper to convert UnifiedClusterState into ClusterPoolState protobuf."""
    pb_nodes = []
    for n in state.nodes:
        hw = n.get("hardware", {})
        gpus = hw.get("gpus", [])
        pb_gpus = [
            desplit_pb2.GPUSpec(
                name=g.get("name", ""),
                vendor=g.get("vendor", ""),
                total_vram_mb=g.get("total_vram_mb", 0),
                free_vram_mb=g.get("free_vram_mb", 0),
                compute_capability=g.get("compute_capability", ""),
                device_index=g.get("device_index", 0),
                temperature_c=g.get("temperature_c", 0.0),
                has_cuda=g.get("has_cuda", False),
            )
            for g in gpus
        ]

        cpu = hw.get("cpu", {})
        pb_cpu = desplit_pb2.CPUSpec(
            name=cpu.get("name", ""),
            architecture=cpu.get("architecture", ""),
            physical_cores=cpu.get("physical_cores", 0),
            logical_cores=cpu.get("logical_cores", 0),
            frequency_mhz=cpu.get("frequency_mhz", 0.0),
            has_avx=cpu.get("has_avx", False),
            has_avx2=cpu.get("has_avx2", False),
            has_avx512=cpu.get("has_avx512", False),
        )

        ram = hw.get("ram", {})
        pb_ram = desplit_pb2.RAMSpec(
            total_ram_mb=ram.get("total_ram_mb", 0),
            available_ram_mb=ram.get("available_ram_mb", 0),
        )

        bench = hw.get("benchmark", {})
        pb_bench = desplit_pb2.ComputeBenchmark(
            cpu_gflops=bench.get("cpu_gflops", 0.0),
            gpu_gflops=bench.get("gpu_gflops", 0.0),
            benchmark_duration_ms=bench.get("benchmark_duration_ms", 0.0),
        )

        pb_hw = desplit_pb2.HardwareSpec(
            gpus=pb_gpus,
            cpu=pb_cpu,
            ram=pb_ram,
            benchmark=pb_bench,
            os_name=hw.get("os_name", ""),
        )

        ep = n.get("endpoint", {})
        pb_ep = desplit_pb2.NodeEndpoint(
            public_ip=ep.get("public_ip", ""),
            public_port=ep.get("public_port", 0),
            local_ip=ep.get("local_ip", ""),
            local_port=ep.get("local_port", 0),
            nat_type=ep.get("nat_type", "Unknown"),
        )

        pb_nodes.append(
            desplit_pb2.NodeInfo(
                node_id=n.get("node_id", ""),
                public_key=n.get("public_key", ""),
                hostname=n.get("hostname", ""),
                endpoint=pb_ep,
                hardware=pb_hw,
                status=desplit_pb2.NODE_STATUS_ONLINE if n.get("status") == "ONLINE" else desplit_pb2.NODE_STATUS_OFFLINE,
                joined_timestamp=int(n.get("joined_timestamp", 0)),
                last_heartbeat_timestamp=int(n.get("last_heartbeat_timestamp", 0)),
                ping_latency_ms=int(n.get("ping_latency_ms", 0)),
            )
        )

    return desplit_pb2.ClusterPoolState(
        cluster_id=state.cluster_id,
        total_nodes=state.total_nodes,
        online_nodes=state.online_nodes,
        total_gpus=state.total_gpus,
        total_vram_mb=state.total_vram_mb,
        total_cpu_cores=state.total_cpu_cores,
        total_ram_mb=state.total_ram_mb,
        combined_gflops=state.combined_gflops,
        nodes=pb_nodes,
        last_updated_timestamp=int(state.last_updated_timestamp),
    )


class PoolServiceServicer(desplit_pb2_grpc.PoolServiceServicer):
    def __init__(self, registry: Optional[GlobalPoolRegistry] = None):
        self.registry = registry or GlobalPoolRegistry()

    def RegisterNode(self, request, context):
        node = request.node
        hw = node.hardware

        gpus_dict = [
            {
                "name": g.name,
                "vendor": g.vendor,
                "total_vram_mb": g.total_vram_mb,
                "free_vram_mb": g.free_vram_mb,
                "compute_capability": g.compute_capability,
                "device_index": g.device_index,
                "temperature_c": g.temperature_c,
                "has_cuda": g.has_cuda,
            }
            for g in hw.gpus
        ]

        cpu_dict = {
            "name": hw.cpu.name,
            "architecture": hw.cpu.architecture,
            "physical_cores": hw.cpu.physical_cores,
            "logical_cores": hw.cpu.logical_cores,
            "frequency_mhz": hw.cpu.frequency_mhz,
            "has_avx": hw.cpu.has_avx,
            "has_avx2": hw.cpu.has_avx2,
            "has_avx512": hw.cpu.has_avx512,
        }

        ram_dict = {
            "total_ram_mb": hw.ram.total_ram_mb,
            "available_ram_mb": hw.ram.available_ram_mb,
        }

        bench_dict = {
            "cpu_gflops": hw.benchmark.cpu_gflops,
            "gpu_gflops": hw.benchmark.gpu_gflops,
            "benchmark_duration_ms": hw.benchmark.benchmark_duration_ms,
        }

        hw_dict = {
            "gpus": gpus_dict,
            "cpu": cpu_dict,
            "ram": ram_dict,
            "benchmark": bench_dict,
            "os_name": hw.os_name,
            "total_vram_mb": sum(g["total_vram_mb"] for g in gpus_dict),
            "free_vram_mb": sum(g["free_vram_mb"] for g in gpus_dict),
        }

        ep_dict = {
            "public_ip": node.endpoint.public_ip,
            "public_port": node.endpoint.public_port,
            "local_ip": node.endpoint.local_ip,
            "local_port": node.endpoint.local_port,
            "nat_type": node.endpoint.nat_type,
        }

        self.registry.register_or_update_node(
            node_id=node.node_id,
            public_key=node.public_key,
            hostname=node.hostname,
            endpoint=ep_dict,
            hardware=hw_dict,
        )

        state = self.registry.get_unified_state()
        return desplit_pb2.RegistrationResponse(
            success=True,
            message="Node successfully registered into DeSplit Global Pool",
            assigned_cluster_id=self.registry.cluster_id,
            current_cluster_state=_build_cluster_state_pb(state),
        )

    def SendHeartbeat(self, request, context):
        ack = self.registry.record_heartbeat(
            node_id=request.node_id,
            free_vram_mb=request.free_vram_mb if request.free_vram_mb > 0 else None,
        )
        state = self.registry.get_unified_state()
        return desplit_pb2.HeartbeatResponse(
            acknowledged=ack,
            server_timestamp=int(time.time()),
            active_nodes_count=state.online_nodes,
        )

    def GetClusterState(self, request, context):
        state = self.registry.get_unified_state()
        return _build_cluster_state_pb(state)

    def UnregisterNode(self, request, context):
        ok = self.registry.unregister_node(request.node_id)
        return desplit_pb2.UnregisterResponse(
            success=ok,
            message="Node unregistered from pool" if ok else "Node not found",
        )


def start_pool_server(
    port: int = 50051,
    registry: Optional[GlobalPoolRegistry] = None,
    max_workers: int = 10,
) -> grpc.Server:
    """Start and return a running gRPC pool server."""
    server = grpc.server(futures.ThreadPoolExecutor(max_workers=max_workers))
    servicer = PoolServiceServicer(registry=registry)
    desplit_pb2_grpc.add_PoolServiceServicer_to_server(servicer, server)
    server.add_insecure_port(f"0.0.0.0:{port}")
    server.start()
    logger.info(f"DeSplit Pool Server listening on 0.0.0.0:{port}")
    return server
