# Intel GPU Roofline Scripts

This folder provides an Intel-oriented workflow aligned with the existing NVIDIA/AMD scripts.
It supports:

- Roofline plots from Intel Advisor CSV exports
- Optional occupancy/predication/instmix histograms when an extra metrics CSV is provided (for example from `unitrace` or VTune CSV export)

## Quick start

```bash
./profile.sh profile EXE=/path/to/your/exe FLAGS="--size 1024"
./profile.sh dat KERNELS=kernelA,kernelB
./profile.sh plot KERNELS=kernelA,kernelB
```

Default outputs:

- `gpu/intel/out/profile.dat`
- `gpu/intel/out/roofline-sp.pdf`
- `gpu/intel/out/roofline-dp.pdf`
- `gpu/intel/out/roofline-inst.pdf`
- `gpu/intel/out/roofline-shared.pdf`
- `gpu/intel/out/instmix.pdf`
- `gpu/intel/out/hist-occupancy.pdf`
- `gpu/intel/out/hist-predication.pdf`

## Inputs and commands

`profile.sh profile` runs Advisor by default:

- collect: `advisor --collect=roofline --profile-gpu ...`
- report: `advisor --report=roofline --gpu --format=csv ... > out/advisor-roofline.csv`

Optional metrics input:

- Provide `METRICS_CSV=/path/to/metrics.csv` before `dat/plot/...`
- Or set `UNITRACE_CMD="... > out/intel-metrics.csv"` during `profile`

## Common variables

- `KERNELS` (required for `dat` and plot targets): comma-separated kernel substrings used for grouping/labels.
- `ROOFLINE_CSV`: Advisor roofline CSV path (default `out/advisor-roofline.csv`).
- `METRICS_CSV`: optional metrics CSV for occupancy/predication/instmix (default `out/intel-metrics.csv`).
- `INTEL2DAT_ARGS`: extra converter args (e.g. `--peak-fp`, `--peak-dp`, `--l1-peak`, `--l2-peak`, `--hbm-peak`).
- `PROFILER_CMD`: full command override for custom collection pipelines.

## Notes

- Intel metric names and schemas differ across tools/versions. `intel2dat` uses tolerant header matching and falls back gracefully when some metrics are unavailable.
- Instruction roofline/shared roofline and histogram plots are best-effort unless the optional metrics CSV contains suitable counters.
- If kernel substrings in `KERNELS` do not match CSV names, those groups will show as zeros and warnings are printed.
