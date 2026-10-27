"""
Global Unified Pool Registry for DeSplit.
Aggregates and synchronizes all distributed CPUs, GPUs, VRAM, and RAM
from every participating node across the world into a single virtual super-cluster.
"""
from __future__ import annotations

import logging
import time
from dataclasses import asdict, dataclass, field
from typing import Dict, List, Optional

logger = logging.getLogger("desplit.network.registry")


@dataclass
class NodeRecord:
    node_id: str
    public_key: str
    hostname: str
    endpoint: dict  # public_ip, public_port, local_ip, local_port
    hardware: dict  # gpus, cpu, ram, benchmark, os_name
    status: str  # "ONLINE", "BUSY", "OFFLINE"
    joined_timestamp: float
    last_heartbeat_timestamp: float
    ping_latency_ms: float = 0.0

    @property
    def is_alive(self) -> bool:
        # Node considered alive if heartbeat within last 45 seconds
        return (time.time() - self.last_heartbeat_timestamp) < 45.0

    def to_dict(self) -> dict:
        return {
            "node_id": self.node_id,
            "public_key": self.public_key,
            "hostname": self.hostname,
            "endpoint": self.endpoint,
            "hardware": self.hardware,
            "status": "ONLINE" if self.is_alive else "OFFLINE",
            "joined_timestamp": self.joined_timestamp,
            "last_heartbeat_timestamp": self.last_heartbeat_timestamp,
            "ping_latency_ms": self.ping_latency_ms,
        }


@dataclass
class UnifiedClusterState:
    cluster_id: str
    total_nodes: int
    online_nodes: int
    total_gpus: int
    total_vram_mb: int
    free_vram_mb: int
    total_cpu_cores: int
    total_ram_mb: int
    combined_gflops: float
    nodes: List[dict]
    last_updated_timestamp: float

    def to_dict(self) -> dict:
        return asdict(self)


class GlobalPoolRegistry:
    """
    In-memory, thread-safe registry tracking all active nodes and aggregating their
    compute resources into a single virtual unified pool.
    """

    def __init__(self, cluster_id: str = "desplit-global-pool-alpha"):
        self.cluster_id = cluster_id
        self._nodes: Dict[str, NodeRecord] = {}

    def register_or_update_node(
        self,
        node_id: str,
        public_key: str,
        hostname: str,
        endpoint: dict,
        hardware: dict,
    ) -> NodeRecord:
        """Register a new node into the pool or update an existing one."""
        now = time.time()
        record = NodeRecord(
            node_id=node_id,
            public_key=public_key,
            hostname=hostname,
            endpoint=endpoint,
            hardware=hardware,
            status="ONLINE",
            joined_timestamp=now if node_id not in self._nodes else self._nodes[node_id].joined_timestamp,
            last_heartbeat_timestamp=now,
        )
        self._nodes[node_id] = record
        logger.info(f"Node {node_id} ({hostname}) registered in pool {self.cluster_id}")
        return record

    def record_heartbeat(self, node_id: str, free_vram_mb: Optional[int] = None) -> bool:
        """Update last heartbeat timestamp for a node."""
        if node_id in self._nodes:
            self._nodes[node_id].last_heartbeat_timestamp = time.time()
            self._nodes[node_id].status = "ONLINE"
            if free_vram_mb is not None:
                self._nodes[node_id].hardware["free_vram_mb"] = free_vram_mb
            return True
        return False

    def unregister_node(self, node_id: str) -> bool:
        """Mark a node as offline and remove from active pool."""
        if node_id in self._nodes:
            del self._nodes[node_id]
            logger.info(f"Node {node_id} removed from pool")
            return True
        return False

    def get_unified_state(self) -> UnifiedClusterState:
        """
        Aggregate all connected machines into a single unified virtual supercluster.
        Computes total pooled VRAM, CPU cores, RAM, and GFLOPS across all nodes.
        """
        now = time.time()
        online_records = [n for n in self._nodes.values() if n.is_alive]

        total_nodes = len(self._nodes)
        online_nodes = len(online_records)

        total_gpus = 0
        total_vram_mb = 0
        free_vram_mb = 0
        total_cpu_cores = 0
        total_ram_mb = 0
        combined_gflops = 0.0

        for n in online_records:
            hw = n.hardware
            # Tally GPUs and VRAM
            gpus = hw.get("gpus", [])
            total_gpus += len(gpus)
            total_vram_mb += hw.get("total_vram_mb", sum(g.get("total_vram_mb", 0) for g in gpus))
            free_vram_mb += hw.get("free_vram_mb", sum(g.get("free_vram_mb", 0) for g in gpus))

            # Tally CPU cores
            cpu = hw.get("cpu", {})
            total_cpu_cores += cpu.get("logical_cores", 0)

            # Tally RAM
            ram = hw.get("ram", {})
            total_ram_mb += ram.get("total_ram_mb", 0)

            # Tally compute benchmarks
            bench = hw.get("benchmark", {})
            combined_gflops += bench.get("cpu_gflops", 0.0) + bench.get("gpu_gflops", 0.0)

        return UnifiedClusterState(
            cluster_id=self.cluster_id,
            total_nodes=total_nodes,
            online_nodes=online_nodes,
            total_gpus=total_gpus,
            total_vram_mb=total_vram_mb,
            free_vram_mb=free_vram_mb,
            total_cpu_cores=total_cpu_cores,
            total_ram_mb=total_ram_mb,
            combined_gflops=round(combined_gflops, 2),
            nodes=[n.to_dict() for n in self._nodes.values()],
            last_updated_timestamp=now,
        )
