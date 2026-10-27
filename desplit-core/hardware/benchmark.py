"""
Rapid Compute Benchmark Module for DeSplit.
Executes lightweight sub-second matrix operations to calculate verified empirical
GFLOPS for CPU and GPU to assess compute capability in the global pool.
"""
from __future__ import annotations

import logging
import time
from dataclasses import asdict, dataclass

logger = logging.getLogger("desplit.hardware.benchmark")


@dataclass
class BenchmarkResult:
    cpu_gflops: float
    gpu_gflops: float
    benchmark_duration_ms: float

    def to_dict(self) -> dict:
        return asdict(self)


def benchmark_cpu(matrix_size: int = 1024, iterations: int = 3) -> float:
    """Benchmark CPU float32 matrix multiplication GFLOPS."""
    try:
        import numpy as np  # type: ignore

        a = np.random.randn(matrix_size, matrix_size).astype(np.float32)
        b = np.random.randn(matrix_size, matrix_size).astype(np.float32)

        # Warmup
        _ = a @ b

        start = time.perf_counter()
        for _ in range(iterations):
            _ = a @ b
        elapsed = time.perf_counter() - start

        # FLOPs = 2 * N^3 operations per matmul
        total_flops = 2.0 * (matrix_size**3) * iterations
        gflops = (total_flops / elapsed) / 1e9
        return round(float(gflops), 2)
    except Exception as e:
        logger.debug(f"CPU numpy benchmark failed: {e}")
        return 25.0  # conservative estimated fallback


def benchmark_gpu(matrix_size: int = 2048, iterations: int = 10) -> float:
    """Benchmark GPU float16/float32 matrix multiplication GFLOPS if CUDA is available."""
    try:
        import torch  # type: ignore

        if not torch.cuda.is_available():
            return 0.0

        device = torch.device("cuda:0")
        a = torch.randn(matrix_size, matrix_size, dtype=torch.float32, device=device)
        b = torch.randn(matrix_size, matrix_size, dtype=torch.float32, device=device)

        # Warmup
        _ = torch.matmul(a, b)
        torch.cuda.synchronize()

        start = time.perf_counter()
        for _ in range(iterations):
            _ = torch.matmul(a, b)
        torch.cuda.synchronize()
        elapsed = time.perf_counter() - start

        total_flops = 2.0 * (matrix_size**3) * iterations
        gflops = (total_flops / elapsed) / 1e9
        return round(float(gflops), 2)
    except Exception as e:
        logger.debug(f"GPU torch benchmark skipped: {e}")
        return 0.0


def run_quick_benchmark() -> BenchmarkResult:
    """Run both CPU and GPU benchmarks and return combined result."""
    t0 = time.perf_counter()
    cpu_gflops = benchmark_cpu()
    gpu_gflops = benchmark_gpu()
    duration_ms = round((time.perf_counter() - t0) * 1000.0, 1)

    return BenchmarkResult(
        cpu_gflops=cpu_gflops,
        gpu_gflops=gpu_gflops,
        benchmark_duration_ms=duration_ms,
    )
