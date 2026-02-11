# GPU Profiling Scripts

Small, opinionated tooling to collect Nsight Compute (and vendor equivalents) metrics
and generate roofline/summary plots for specific kernels. It is meant for repeatable
profiling runs rather than one-off GUI sessions.

Vendors supported today:
- NVIDIA (Nsight Compute)
- AMD (ROCProfiler/rocprof-style workflows)

The repository is organized under `gpu/<vendor>/`.

- `gpu/README.md` explains the hierarchy.
- `gpu/nvidia/README.md` covers NVIDIA usage and tooling.
- `gpu/amd/README.md` covers AMD usage and tooling.

## Acknowledgements

- Original idea and inspiration: `https://github.com/nazavode/gpu-charts`
- Roofline inspiration: N. Ding and S. Williams, “An Instruction Roofline Model for GPUs,” in 2019 IEEE/ACM Performance Modeling, Benchmarking and Simulation of High Performance Computer Systems (PMBS), Denver, CO, USA: IEEE, Nov. 2019, pp. 7–18. doi: 10.1109/PMBS49563.2019.00007.
