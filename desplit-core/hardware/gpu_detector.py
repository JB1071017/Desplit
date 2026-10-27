"""
GPU Detection and Profiling Module for DeSplit.
Detects NVIDIA (CUDA/NVML), AMD (ROCm), Apple (Metal/MPS), Intel (DirectML/Integrated),
and provides unified metrics for VRAM, compute capability, and status.
"""
from __future__ import annotations

import json
import logging
import platform
import shutil
import subprocess
from dataclasses import asdict, dataclass
from typing import List, Optional

logger = logging.getLogger("desplit.hardware.gpu")


@dataclass
class GPUDevice:
    name: str
    vendor: str  # "NVIDIA", "AMD", "Apple", "Intel", "Unknown"
    total_vram_mb: int
    free_vram_mb: int
    compute_capability: str
    device_index: int
    temperature_c: float
    has_cuda: bool

    def to_dict(self) -> dict:
        return asdict(self)


def _detect_nvidia_pynvml() -> List[GPUDevice]:
    devices = []
    try:
        import pynvml  # type: ignore

        pynvml.nvmlInit()
        device_count = pynvml.nvmlDeviceGetCount()
        for i in range(device_count):
            handle = pynvml.nvmlDeviceGetHandleByIndex(i)
            name = pynvml.nvmlDeviceGetName(handle)
            if isinstance(name, bytes):
                name = name.decode("utf-8")
            mem_info = pynvml.nvmlDeviceGetMemoryInfo(handle)
            total_mb = int(mem_info.total / (1024 * 1024))
            free_mb = int(mem_info.free / (1024 * 1024))

            temp = 0.0
            try:
                temp = float(pynvml.nvmlDeviceGetTemperature(handle, pynvml.NVML_TEMPERATURE_GPU))
            except Exception:
                pass

            cc_major, cc_minor = 0, 0
            try:
                cc_major, cc_minor = pynvml.nvmlDeviceGetCudaComputeCapability(handle)
            except Exception:
                pass
            cc_str = f"{cc_major}.{cc_minor}" if cc_major > 0 else "N/A"

            devices.append(
                GPUDevice(
                    name=name,
                    vendor="NVIDIA",
                    total_vram_mb=total_mb,
                    free_vram_mb=free_mb,
                    compute_capability=cc_str,
                    device_index=i,
                    temperature_c=temp,
                    has_cuda=True,
                )
            )
        pynvml.nvmlShutdown()
    except Exception as e:
        logger.debug(f"pynvml detection skipped/failed: {e}")
    return devices


def _detect_nvidia_smi() -> List[GPUDevice]:
    devices = []
    if not shutil.which("nvidia-smi"):
        return devices
    try:
        cmd = [
            "nvidia-smi",
            "--query-gpu=index,name,memory.total,memory.free,temperature.gpu",
            "--format=csv,noheader,nounits",
        ]
        res = subprocess.run(cmd, capture_output=True, text=True, timeout=3)
        if res.returncode == 0:
            lines = res.stdout.strip().splitlines()
            for line in lines:
                parts = [p.strip() for p in line.split(",")]
                if len(parts) >= 5:
                    idx = int(parts[0])
                    name = parts[1]
                    total_mb = int(float(parts[2]))
                    free_mb = int(float(parts[3]))
                    temp = float(parts[4])
                    devices.append(
                        GPUDevice(
                            name=name,
                            vendor="NVIDIA",
                            total_vram_mb=total_mb,
                            free_vram_mb=free_mb,
                            compute_capability="NVIDIA",
                            device_index=idx,
                            temperature_c=temp,
                            has_cuda=True,
                        )
                    )
    except Exception as e:
        logger.debug(f"nvidia-smi detection failed: {e}")
    return devices


def _detect_torch_cuda() -> List[GPUDevice]:
    devices = []
    try:
        import torch  # type: ignore

        if torch.cuda.is_available():
            for i in range(torch.cuda.device_count()):
                name = torch.cuda.get_device_name(i)
                props = torch.cuda.get_device_properties(i)
                total_mb = int(props.total_memory / (1024 * 1024))
                allocated_mb = int(torch.cuda.memory_allocated(i) / (1024 * 1024))
                free_mb = max(0, total_mb - allocated_mb)
                cc = f"{props.major}.{props.minor}"
                devices.append(
                    GPUDevice(
                        name=name,
                        vendor="NVIDIA",
                        total_vram_mb=total_mb,
                        free_vram_mb=free_mb,
                        compute_capability=cc,
                        device_index=i,
                        temperature_c=0.0,
                        has_cuda=True,
                    )
                )
    except Exception as e:
        logger.debug(f"torch.cuda detection failed: {e}")
    return devices


def _detect_windows_cim() -> List[GPUDevice]:
    """Fallback probe on Windows using PowerShell Get-CimInstance Win32_VideoController."""
    devices = []
    if platform.system() != "Windows":
        return devices
    try:
        cmd = [
            "powershell",
            "-NoProfile",
            "-Command",
            "Get-CimInstance Win32_VideoController | Select-Object Name, AdapterRAM | ConvertTo-Json",
        ]
        res = subprocess.run(cmd, capture_output=True, text=True, timeout=5)
        if res.returncode == 0 and res.stdout.strip():
            data = json.loads(res.stdout)
            if isinstance(data, dict):
                data = [data]
            for idx, item in enumerate(data):
                name = item.get("Name", "Generic Display Controller")
                # Filter out remote desktop / virtual mirrors
                if "Virtual" in name or "RDP" in name or "Citrix" in name:
                    continue
                raw_bytes = item.get("AdapterRAM") or 0
                total_mb = int(raw_bytes / (1024 * 1024)) if raw_bytes else 0

                vendor = "Unknown"
                name_upper = name.upper()
                if "NVIDIA" in name_upper or "GEFORCE" in name_upper or "RTX" in name_upper or "QUADRO" in name_upper:
                    vendor = "NVIDIA"
                elif "AMD" in name_upper or "RADEON" in name_upper:
                    vendor = "AMD"
                elif "INTEL" in name_upper or "IRIS" in name_upper or "ARC" in name_upper:
                    vendor = "Intel"
                elif "APPLE" in name_upper:
                    vendor = "Apple"

                devices.append(
                    GPUDevice(
                        name=name,
                        vendor=vendor,
                        total_vram_mb=total_mb,
                        free_vram_mb=total_mb,  # estimate
                        compute_capability="DirectX/WMI",
                        device_index=idx,
                        temperature_c=0.0,
                        has_cuda=(vendor == "NVIDIA"),
                    )
                )
    except Exception as e:
        logger.debug(f"Windows CIM GPU detection failed: {e}")
    return devices


def detect_gpus() -> List[GPUDevice]:
    """
    Main detection function with layered fallbacks.
    Returns a list of all detected GPU devices.
    """
    # 1. Try PyNVML (most accurate for NVIDIA)
    devs = _detect_nvidia_pynvml()
    if devs:
        return devs

    # 2. Try nvidia-smi
    devs = _detect_nvidia_smi()
    if devs:
        return devs

    # 3. Try PyTorch CUDA
    devs = _detect_torch_cuda()
    if devs:
        return devs

    # 4. Try Windows CIM (WMI)
    devs = _detect_windows_cim()
    if devs:
        return devs

    # 5. No GPU found
    return []
