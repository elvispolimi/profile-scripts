# AMD GPU Roofline (CDNA / MI200 / MI300)

This folder provides a workflow similar to the NVIDIA path, but for AMD CDNA GPUs using ROCm profiling tools.

## Tools
- Preferred: `rocprof-compute` (ROCm Compute Profiler, the successor to Omniperf)
- Also supported: `omniperf`

Both tools produce a workload directory containing `pmc_perf.csv` and `roofline.csv`, which are converted into a gnuplot `.dat` file.

## Quick start
```bash
make -C gpu/amd profile EXE=/path/to/your/exe KERNELS=kernelA,kernelB
make -C gpu/amd dat KERNELS=kernelA,kernelB
make -C gpu/amd plot KERNELS=kernelA,kernelB
```

Outputs:
- `gpu/amd/out/profile.dat`
- `gpu/amd/out/roofline-fp32.pdf`

## Common variables
- `KERNELS` (required): comma-separated kernel name substrings used to group and label kernels.
- `EXE`, `FLAGS`: executable and its arguments.
- `WORKLOAD`: name for the profiler run directory (default: `profile`).
- `SOC`: optional, set to the specific SOC directory under `workloads/WORKLOAD`.
- `PROFILER`: profiler binary (`rocprof-compute` or `omniperf`).
- `PROFILER_ARGS`: extra profiler args (e.g., device selection).
- `PROFILER_CMD`: full command override if you want a custom invocation.
- `ROOFLINE_PRECISION`: `fp32` or `fp64`.

## Notes
- `omniperf2dat` tries to find common column names in `pmc_perf.csv` / `roofline.csv`. If it fails, it prints the headers it found and suggests the missing columns.
- Overlapping `KERNELS` substrings will aggregate multiple kernels under the first match.

## Example with Omniperf
```bash
make -C gpu/amd profile \
  PROFILER=omniperf \
  PROFILER_CMD="omniperf profile -n profile -- /path/to/your/exe --args" \
  KERNELS=kernelA,kernelB
```
