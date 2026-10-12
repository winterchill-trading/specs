# The Uncertain Art of Accelerating ML Models

- Source: <https://signalsandthreads.com/the-uncertain-art-of-accelerating-ml-models/>
- Published: 2024-10-14
- Kind: Signals and Threads episode 21

## Summary

- The guest is an ML performance engineer at Jane Street. Earlier roles: maths teacher,
  fast.ai (library, courses and a co-written book), and maintainer of Hugging Face
  Transformers and author of Hugging Face Accelerate.
- fast.ai's mission is to teach domain experts (radiologists, traders) enough deep
  learning to shape models with their own data knowledge.
- In the DAWNBench speed-to-accuracy contest the fast.ai entry led until TPUs were
  released. Two techniques: a learning-rate schedule that warms up from low to high then
  decays (now standard for transformers), and progressive resizing, training a CNN on
  128x128 images first and raising resolution later.
- Warm-up works because a randomly initialized model sits on very spiky terrain in some
  of its millions of dimensions; the host warns that 2D or 3D intuitions mislead.
- Accelerate replaced Hugging Face's monolithic trainer (spaghetti of flags) with a few
  changed lines in the researcher's own loop. It hides data parallelism, CPU/GPU/TPU
  differences and mixed precision boilerplate.
- Parallelism types: data parallel (split batches across GPUs); pipeline parallel (layers
  on different GPUs, with micro-batches interleaving forward and backward passes); tensor
  parallel (weights split across GPUs, demanding very fast interconnect).
- Interconnect matters: RDMA (described by the host as CPU bypass, straight into GPU
  memory), NVLink within a box, and 72-GPU single-rack designs; InfiniBand roots in
  supercomputing.
- PyTorch dispatches kernels asynchronously from Python. Slowness usually comes from
  hidden CPU-GPU synchronization (for example a Python branch on whether the loss is
  NaN) and from kernel launch overhead of microseconds or more per kernel.
- Fix for the NaN check: run it on a side thread and let the main loop keep going,
  accepting a few wasted iterations before the job stops.
- PyTorch beat TensorFlow and JAX on flexibility for experiments and ragged data, then
  added `torch.compile` anyway, because modern GPUs finish kernels faster than Python can
  launch them. The compiler captures the graph and fuses kernels via Triton templates.
- Fusion saves both launch overhead and the write-then-read of intermediates in GPU
  memory. CUDA graphs record and replay launches (no fusion); CUDA streams hint that
  independent work, such as a host-to-device copy and compute, can overlap.
- GPU programming stack: CUDA (C-like, unsafe, hard to debug), Triton (Python DSL, good
  at matmul-like code, opaque errors), Mojo, Mosaic GPU and TPU, and Numba.
- GPU threads: warps of 32 in lockstep, blocks of up to 1,024 threads per streaming
  multiprocessor with shared memory, and a register file of about 65K per SM.
  Near-zero context switches let warps hide memory latency.
- Mixed precision multiplies in float16 or bfloat16 and accumulates in float32 for a
  roughly 2x to 4x speedup on tensor cores; hardware now offers 8-bit and 4-bit formats.
- The host ties this to OxCaml: the key to performance engineering is giving users
  explicit control rather than relying on compiler magic.
- The firm is adding routine profiling of all training jobs to flag slow steps to
  researchers; some novel layers still need custom Triton or CUDA kernels.
- Internal gap: training infrastructure is drifting toward the same monolithic trainer
  pattern; the guest favours small composable building blocks for expert researchers.
- Market data differs from text and images. It is very noisy because traded-on signal
  disappears, prices are close to a random walk, and it is non-stationary as markets
  adapt to strategies.
- Market data is also huge (terabytes per day). Models are smaller with a different
  compute-to-bytes ratio. Some must keep up with up to a million events per stock per
  day at a few microseconds each, and the firm needs latency budgets from 100 ns to hours.
- Custom data loaders and custom architectures are the main internal differences; the
  firm also runs an ML bootcamp for traders every few months.
- Variable-length samples stall distributed training at barriers; bucketing by length
  balances GPUs at some cost in shuffle randomness.
- Reproducibility is the hardest lesson: record code revision, package versions and
  hyperparameter config; notebooks run out of order; GPU float sums are non-associative,
  so runs differ unless you pay a large performance cost.

## Relevance to us

- Mostly out of scope: we train no models and use no GPUs. The relevant parts are
  reproducibility of derived data and the profile-first approach to speed.
- **Data platform:** a derived dataset is only trustworthy if you can say exactly which
  inputs and code produced it, and our [parquet](../../../repos/parquet.md) writer cannot
  store key-value metadata. **Action:** have `day-close` write a `manifest.sexp` next to
  each day's tables listing input event-log files with sizes and the build's version
  string, with an expect test, in [market-data](../../../repos/market-data.md).
- **Performance:** most wins come from profiling once and removing one hidden bottleneck,
  and a market data consumer has a few microseconds per event to keep up. **Action:**
  add a `core_bench` benchmark that runs the Binance `Feed_normalizer` over a recorded
  minute file and reports nanoseconds per frame, in
  [binance-client](../../../repos/binance-client.md).
- [market-maker](../../../repos/market-maker.md) runs are not bit-repeatable, which,
  like GPU training, is tolerable only while the cause (request timing) is known and
  documented.

Tags: `ml`, `performance`, `data-platform`, `research-tooling`
