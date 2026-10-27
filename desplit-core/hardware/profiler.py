"""
Master Hardware Profiler for DeSplit.
Aggregates GPU, CPU, RAM, and benchmark metrics into a unified HardwareProfile.
"""
from __future__ import annotations

import platform
from dataclasses import asdict, dataclass
from typing import List

from .benchmark import BenchmarkResult, run_quick_benchmark
from .cpu_detector import CPUSpec, RAMSpec, detect_cpu, detect_ram
from .gpu_detector import GPUDevice, detect_gpus


@dataclass
class HardwareProfile:
    gpus: List[GPUDevice]
    cpu: CPUSpec
    ram: RAMSpec
    benchmark: BenchmarkResult
    os_name: str

    @property
    def has_dedicated_gpu(self) -> bool:
        return any(g.total_vram_mb > 1024 and g.vendor != "Intel" for g in self.gpus)

    @property
    def total_vram_mb(self) -> int:
        return sum(g.total_vram_mb for g in self.gpus)

    @property
    def free_vram_mb(self) -> int:
        return sum(g.free_vram_mb for g in self.gpus)

    def to_dict(self) -> dict:
        return {
            "gpus": [g.to_dict() for g in self.gpus],
            "cpu": self.cpu.to_dict(),
            "ram": self.ram.to_dict(),
            "benchmark": self.benchmark.to_dict(),
            "os_name": self.os_name,
            "has_dedicated_gpu": self.has_dedicated_gpu,
            "total_vram_mb": self.total_vram_mb,
            "free_vram_mb": self.free_vram_mb,
        }


def profile_local_hardware(run_benchmark: bool = True) -> HardwareProfile:
    """
    Profile all local compute hardware on this machine.
    Returns complete HardwareProfile.
    """
    gpus = detect_gpus()
    cpu = detect_cpu()
    ram = detect_ram()
    benchmark = (
        run_quick_benchmark()
        if run_benchmark
        else BenchmarkResult(cpu_gflops=0.0, gpu_gflops=0.0, benchmark_duration_ms=0.0)
    )
    os_name = f"{platform.system()} {platform.release()} ({platform.architecture()[0]})"

    return HardwareProfile(
        gpus=gpus,
        cpu=cpu,
        ram=ram,
        benchmark=benchmark,
        os_name=os_name,
    )
