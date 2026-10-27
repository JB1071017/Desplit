"""Hardware discovery and profiling package for DeSplit."""
from .gpu_detector import GPUDevice, detect_gpus
from .cpu_detector import CPUSpec, detect_cpu, detect_ram, RAMSpec
from .benchmark import run_quick_benchmark, BenchmarkResult
from .profiler import HardwareProfile, profile_local_hardware

__all__ = [
    "GPUDevice",
    "detect_gpus",
    "CPUSpec",
    "detect_cpu",
    "RAMSpec",
    "detect_ram",
    "BenchmarkResult",
    "run_quick_benchmark",
    "HardwareProfile",
    "profile_local_hardware",
]
