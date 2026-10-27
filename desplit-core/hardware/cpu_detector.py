"""
CPU and RAM Detection Module for DeSplit.
Detects processor name, architecture, physical/logical core counts,
SIMD features (AVX, AVX2, AVX-512), and real-time RAM capacity.
"""
from __future__ import annotations

import logging
import os
import platform
import subprocess
from dataclasses import asdict, dataclass

import psutil

logger = logging.getLogger("desplit.hardware.cpu")


@dataclass
class CPUSpec:
    name: str
    architecture: str
    physical_cores: int
    logical_cores: int
    frequency_mhz: float
    has_avx: bool
    has_avx2: bool
    has_avx512: bool

    def to_dict(self) -> dict:
        return asdict(self)


@dataclass
class RAMSpec:
    total_ram_mb: int
    available_ram_mb: int

    def to_dict(self) -> dict:
        return asdict(self)


def _detect_cpu_name() -> str:
    """Detect human-readable CPU brand string across platforms."""
    name = platform.processor()
    system = platform.system()

    if system == "Windows":
        try:
            # Query registry or wmic
            import winreg

            key = winreg.OpenKey(
                winreg.HKEY_LOCAL_MACHINE,
                r"HARDWARE\DESCRIPTION\System\CentralProcessor\0",
            )
            brand, _ = winreg.QueryValueEx(key, "ProcessorNameString")
            winreg.CloseKey(key)
            if brand and brand.strip():
                return brand.strip()
        except Exception:
            pass

    elif system == "Darwin":
        try:
            res = subprocess.run(["sysctl", "-n", "machdep.cpu.brand_string"], capture_output=True, text=True)
            if res.returncode == 0 and res.stdout.strip():
                return res.stdout.strip()
        except Exception:
            pass

    elif system == "Linux":
        try:
            with open("/proc/cpuinfo", "r") as f:
                for line in f:
                    if "model name" in line:
                        return line.split(":", 1)[1].strip()
        except Exception:
            pass

    return name or "Generic CPU"


def _detect_simd_flags() -> tuple[bool, bool, bool]:
    """Detect AVX, AVX2, and AVX-512 extensions."""
    has_avx = False
    has_avx2 = False
    has_avx512 = False

    try:
        # Check cpuinfo if available
        import cpuinfo  # type: ignore

        info = cpuinfo.get_cpu_info()
        flags = [f.lower() for f in info.get("flags", [])]
        has_avx = "avx" in flags
        has_avx2 = "avx2" in flags
        has_avx512 = any("avx512" in f for f in flags)
        return has_avx, has_avx2, has_avx512
    except Exception:
        pass

    # Heuristic fallback based on modern x86_64
    arch = platform.machine().lower()
    if "x86_64" in arch or "amd64" in arch:
        # Nearly all modern 64-bit consumer CPUs from 2013+ have AVX & AVX2
        has_avx = True
        has_avx2 = True

    return has_avx, has_avx2, has_avx512


def detect_cpu() -> CPUSpec:
    name = _detect_cpu_name()
    arch = platform.machine()
    physical = psutil.cpu_count(logical=False) or os.cpu_count() or 1
    logical = psutil.cpu_count(logical=True) or os.cpu_count() or 1

    freq_mhz = 0.0
    try:
        freq = psutil.cpu_freq()
        if freq:
            freq_mhz = float(freq.current or freq.max or 0.0)
    except Exception:
        pass

    has_avx, has_avx2, has_avx512 = _detect_simd_flags()

    return CPUSpec(
        name=name,
        architecture=arch,
        physical_cores=physical,
        logical_cores=logical,
        frequency_mhz=freq_mhz,
        has_avx=has_avx,
        has_avx2=has_avx2,
        has_avx512=has_avx512,
    )


def detect_ram() -> RAMSpec:
    v = psutil.virtual_memory()
    total_mb = int(v.total / (1024 * 1024))
    avail_mb = int(v.available / (1024 * 1024))
    return RAMSpec(total_ram_mb=total_mb, available_ram_mb=avail_mb)
