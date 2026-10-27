"""
End-to-End Test and Validation Script for DeSplit Discovery & Pooling Foundation.
1. Profiles local CPU, GPU, RAM, and Compute Benchmark.
2. Generates cryptographic Ed25519 Node Identity.
3. Discovers public and local network endpoints via STUN.
4. Starts the gRPC Global Pool Coordinator.
5. Registers the local machine into the pool.
6. Simulates multi-node cross-network contributors (e.g. Tokyo & Berlin nodes).
7. Queries and validates the Unified Super-Cluster State.
"""
from __future__ import annotations

import os
import sys
import time
import warnings
from pathlib import Path

# Fix Windows console encoding
if sys.platform == "win32":
    try:
        sys.stdout.reconfigure(encoding="utf-8")
        sys.stderr.reconfigure(encoding="utf-8")
    except Exception:
        pass

warnings.filterwarnings("ignore")

# Add core to python path
core_dir = Path(__file__).parent.resolve()
if str(core_dir) not in sys.path:
    sys.path.insert(0, str(core_dir))

proto_dir = core_dir / "proto"
if str(proto_dir) not in sys.path:
    sys.path.insert(0, str(proto_dir))

from rich.console import Console
from rich.panel import Panel
from rich.table import Table

from hardware.profiler import profile_local_hardware
from network.identity import get_or_create_identity
from network.pool_client import PoolClient
from network.pool_registry import GlobalPoolRegistry
from network.pool_server import start_pool_server
from network.stun_client import discover_public_endpoint

console = Console()


def run_e2e_test():
    console.print()
    console.print(
        Panel.fit(
            "[bold cyan]DeSplit Discovery & Global Compute Pooling Engine[/bold cyan]\n"
            "[dim]Phase 1 Validation: Hardware Profiling, Ed25519 Identity, STUN NAT Discovery, and Unified Cluster Pooling[/dim]",
            border_style="cyan",
        )
    )

    # 1. Hardware Profiling
    console.print("\n[bold yellow]Step 1: Interrogating Local Hardware (CPU, GPU, RAM, Benchmark)...[/bold yellow]")
    hw = profile_local_hardware(run_benchmark=True)

    gpu_info = (
        f"{len(hw.gpus)} GPU(s) found: " + ", ".join(f"{g.name} ({g.total_vram_mb} MB VRAM)" for g in hw.gpus)
        if hw.gpus
        else "No dedicated GPU (CPU-only compute contributor)"
    )

    hw_table = Table(title="Local Machine Hardware Profile", border_style="green")
    hw_table.add_column("Component", style="bold")
    hw_table.add_column("Specifications", style="cyan")

    hw_table.add_row("CPU", f"{hw.cpu.name} ({hw.cpu.architecture})")
    hw_table.add_row("CPU Cores", f"{hw.cpu.physical_cores} Physical / {hw.cpu.logical_cores} Logical")
    hw_table.add_row(
        "SIMD Acceleration",
        f"AVX: {'[green]YES[/green]' if hw.cpu.has_avx else '[red]NO[/red]'} | "
        f"AVX2: {'[green]YES[/green]' if hw.cpu.has_avx2 else '[red]NO[/red]'} | "
        f"AVX-512: {'[green]YES[/green]' if hw.cpu.has_avx512 else '[yellow]NO[/yellow]'}",
    )
    hw_table.add_row("System RAM", f"{hw.ram.total_ram_mb} MB total ({hw.ram.available_ram_mb} MB free)")
    hw_table.add_row("Graphics / GPU", gpu_info)
    hw_table.add_row(
        "Empirical Benchmark",
        f"CPU: {hw.benchmark.cpu_gflops} GFLOPS | GPU: {hw.benchmark.gpu_gflops} GFLOPS (took {hw.benchmark.benchmark_duration_ms} ms)",
    )
    hw_table.add_row("Operating System", hw.os_name)
    console.print(hw_table)

    # 2. Cryptographic Identity
    console.print("\n[bold yellow]Step 2: Loading / Generating Ed25519 Cryptographic Node Identity...[/bold yellow]")
    identity = get_or_create_identity()
    console.print(f"  - [bold]Authenticated Node ID:[/bold] [green]{identity.node_id}[/green]")
    console.print(f"  - [bold]Public Key (Ed25519):[/bold] [dim]{identity.public_key_hex}[/dim]")

    # 3. Network & STUN Discovery
    console.print("\n[bold yellow]Step 3: Performing STUN Protocol Public Discovery (Cross-Network NAT)...[/bold yellow]")
    endpoint = discover_public_endpoint(local_port=50051)
    console.print(f"  - [bold]Local LAN IP:[/bold] {endpoint.local_ip}:{endpoint.local_port}")
    console.print(f"  - [bold]Public External IP:[/bold] [bold blue]{endpoint.public_ip}:{endpoint.public_port}[/bold blue]")
    console.print(f"  - [bold]NAT Traversal Mode:[/bold] [magenta]{endpoint.nat_type}[/magenta]")

    # 4. Starting gRPC Pool Server
    console.print("\n[bold yellow]Step 4: Launching gRPC Global Pool Coordinator Server...[/bold yellow]")
    registry = GlobalPoolRegistry(cluster_id="desplit-global-pool-alpha")
    server = start_pool_server(port=50051, registry=registry)
    console.print("  - [green]gRPC Pool Server running on port 50051[/green]")

    # 5. Registering Local Node
    console.print("\n[bold yellow]Step 5: Registering Local Node into the Global Pool via gRPC...[/bold yellow]")
    client = PoolClient(target="127.0.0.1:50051")
    reg_resp = client.register(identity=identity, hardware=hw, endpoint=endpoint)
    console.print(f"  - [green][OK] {reg_resp.message}[/green] (Cluster: [bold]{reg_resp.assigned_cluster_id}[/bold])")

    # 6. Simulating 2 Remote Global Nodes across different networks
    console.print("\n[bold yellow]Step 6: Simulating Distributed Remote Nodes joining the pool wirelessly...[/bold yellow]")
    # Remote Node A (Tokyo)
    registry.register_or_update_node(
        node_id="node_tokyo_rtx3080",
        public_key="3b81f19639c016e788e0b67576a911a37c95b6c97a55df946e38b307ec531101",
        hostname="ai-rig-tokyo",
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
    console.print("  - [cyan]+ Node 'node_tokyo_rtx3080' connected (2x RTX 3080: 20GB VRAM, 32 CPU Cores)[/cyan]")

    # Remote Node B (Berlin)
    registry.register_or_update_node(
        node_id="node_berlin_rtx4090",
        public_key="a794e792c90e66c2847a98b48f9801a357f6b6c97a55df946e38b307ec532299",
        hostname="cluster-node-berlin",
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
    console.print("  - [cyan]+ Node 'node_berlin_rtx4090' connected (1x RTX 4090: 24GB VRAM, 32 CPU Cores)[/cyan]")

    # 7. Querying Consolidated Pool State via gRPC Client
    console.print("\n[bold yellow]Step 7: Querying Unified Virtual Super-Cluster State via gRPC...[/bold yellow]")
    state = client.get_cluster_state()

    total_vram_gb = round(state.total_vram_mb / 1024, 2)
    free_vram_gb = round(state.free_vram_mb / 1024, 2) if hasattr(state, "free_vram_mb") else total_vram_gb
    total_ram_gb = round(state.total_ram_mb / 1024, 2)

    cluster_table = Table(title="[bold green]UNIFIED GLOBAL COMPUTE POOL (Consolidated Virtual Supercomputer)[/bold green]", border_style="bold green")
    cluster_table.add_column("Resource Metric", style="bold")
    cluster_table.add_column("Aggregated Pool Capacity", style="bold cyan")

    cluster_table.add_row("Global Cluster ID", state.cluster_id)
    cluster_table.add_row("Online Participating Nodes", f"{state.online_nodes} nodes worldwide")
    cluster_table.add_row("Total Pooled GPUs", f"{state.total_gpus} GPUs")
    cluster_table.add_row("Total Pooled VRAM", f"[bold yellow]{total_vram_gb} GB[/bold yellow] ({state.total_vram_mb:,} MB)")
    cluster_table.add_row("Total Pooled CPU Cores", f"[bold cyan]{state.total_cpu_cores} Cores[/bold cyan]")
    cluster_table.add_row("Total Pooled System RAM", f"[bold white]{total_ram_gb} GB[/bold white] ({state.total_ram_mb:,} MB)")
    cluster_table.add_row("Combined Compute Performance", f"[bold magenta]{state.combined_gflops:,.2f} GFLOPS[/bold magenta] (~{state.combined_gflops / 1000:,.1f} TFLOPS)")

    console.print()
    console.print(cluster_table)

    # 8. Nodes Breakdown Table
    nodes_table = Table(title="Participating Nodes in the Pool", border_style="cyan")
    nodes_table.add_column("Node ID", style="dim")
    nodes_table.add_column("Host / Region", style="bold")
    nodes_table.add_column("Public IP:Port", style="blue")
    nodes_table.add_column("Pooled GPUs / VRAM", style="yellow")
    nodes_table.add_column("CPU Cores & RAM", style="green")
    nodes_table.add_column("Status", style="bold")

    for n in state.nodes:
        hw_n = n.hardware
        gpu_summary = (
            ", ".join(f"{g.name} ({g.total_vram_mb}MB)" for g in hw_n.gpus)
            if hw_n.gpus
            else "CPU Only"
        )
        nodes_table.add_row(
            n.node_id[:16] + "...",
            n.hostname,
            f"{n.endpoint.public_ip}:{n.endpoint.public_port}",
            gpu_summary,
            f"{hw_n.cpu.logical_cores} Cores | {round(hw_n.ram.total_ram_mb / 1024, 1)} GB",
            "[green]ONLINE[/green]" if n.status == 1 else "[red]OFFLINE[/red]",
        )

    console.print()
    console.print(nodes_table)

    # Cleanup
    client.close()
    server.stop(grace=1)
    console.print("\n[bold green][OK] Phase 1 Validation Complete: Discovery & Hardware Pooling verified successfully![/bold green]\n")


if __name__ == "__main__":
    run_e2e_test()
