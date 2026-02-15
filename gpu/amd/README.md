# AMD GPU Roofline (CDNA / MI200 / MI300)

This folder provides a workflow similar to the NVIDIA path, but for AMD CDNA GPUs using ROCm profiling tools.

## Tools
- Preferred: `rocprof-compute` (ROCm Compute Profiler, the successor to Omniperf)
- Also supported: `omniperf`

Both tools produce a workload directory containing `pmc_perf.csv` and `roofline.csv`, which are converted into a gnuplot `.dat` file.

## Quick start
```bash
./profile.sh profile EXE=/path/to/your/exe KERNELS=kernelA,kernelB
./profile.sh dat KERNELS=kernelA,kernelB
./profile.sh all KERNELS=kernelA,kernelB
```

Outputs:
- `gpu/amd/out/profile.dat`
- `gpu/amd/out/roofline-fp32.pdf`
- `gpu/amd/out/roofline-fp64.pdf`
- `gpu/amd/out/roofline-inst.pdf`
- `gpu/amd/out/roofline-shared.pdf`
- `gpu/amd/out/instmix.pdf` (with full profiling counters)
- `gpu/amd/out/hist-occupancy.pdf` (best-effort from available occupancy columns)
- `gpu/amd/out/hist-predication.pdf` (best-effort from available efficiency columns)

## Common variables
- `KERNELS` (required): comma-separated kernel name substrings used to group and label kernels.
- `EXE`, `FLAGS`: executable and its arguments.
- `WORKLOAD`: name for the profiler run directory (default: `profile`).
- `SOC`: optional, set to the specific SOC directory under `workloads/WORKLOAD`.
- `PROFILER`: profiler binary (`rocprof-compute` or `omniperf`).
- `PROFILER_ARGS`: extra profiler args (e.g., device selection).
- `PROFILER_CMD`: full command override if you want a custom invocation.
- `ROOFLINE_PRECISION`: `fp32` or `fp64`.
- `ROOF_ONLY`: set to `0` to enable full profiling (required for instruction mix).
- `PSTOPDF`: `ps2pdf` binary used to convert PostScript outputs to PDF.

## Targets
- `./profile.sh` or `./profile.sh all`: build all plots.
- `./profile.sh fp`: build only FP32 roofline.
- `./profile.sh dp`: build only FP64 roofline.
- `./profile.sh inst`: build instruction roofline.
- `./profile.sh shared`: build shared/LDS roofline.
- `./profile.sh instmix`: build instruction mix histogram.
- `./profile.sh occupancy`: build occupancy histogram.
- `./profile.sh predication`: build efficiency histogram.
- `./profile.sh clean`: remove generated files.

## Notes
- `omniperf2dat` tries to find common column names in `pmc_perf.csv` / `roofline.csv`. If your ROCm version uses different names, use override flags such as `--occupancy-col` / `--efficiency-col` through `AMD2DAT`.
- Overlapping `KERNELS` substrings will aggregate multiple kernels under the first match.
- Instruction/shared rooflines and occupancy/predication use best-effort metric mapping for AMD and may require column overrides per ROCm/GPU generation.

## Example with Omniperf
```bash
./profile.sh profile \
  PROFILER=omniperf \
  PROFILER_CMD="omniperf profile -n profile -- /path/to/your/exe --args" \
  KERNELS=kernelA,kernelB
```

## Instruction mix
To generate instmix plots, run with full profiling and then:
```bash
./profile.sh profile ROOF_ONLY=0 KERNELS=kernelA,kernelB
./profile.sh dat KERNELS=kernelA,kernelB
./profile.sh instmix
```

For all non-roof-only plots in one shot:
```bash
./profile.sh profile ROOF_ONLY=0 EXE=/path/to/your/exe KERNELS=kernelA,kernelB
./profile.sh all KERNELS=kernelA,kernelB
```
