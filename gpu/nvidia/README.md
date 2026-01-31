# profile-nvidia-scripts

Location in repo hierarchy:

- `gpu/` groups GPU-related tooling by vendor.
- `gpu/nvidia/` holds NVIDIA-specific scripts. Architecture-specific subfolders may be added later.

Make-based pipeline to profile a single executable with Nsight Compute (ncu),
convert metrics into gnuplot variables, and generate roofline and instruction
mix plots. Plot data is derived from a single raw NCU report.

## Quick start

Run the executable and build all plots (kernel list required):

```sh
make EXE=/absolute/path/to/your/exe KERNELS=kernelA,kernelB
```

Outputs are written under `out/` by default:

- `out/roofline-sp.pdf`
- `out/roofline-dp.pdf`
- `out/roofline-inst.pdf`
- `out/instmix.pdf`

Note: the pipeline uses only raw output (`--page raw`) and requests the metrics
listed in `METRICS`.

## Targets

- `make` builds all plots.
- `make fp` builds only the SP roofline.
- `make inst` builds only the instruction roofline.
- `make instmix` builds only the instruction mix histogram.
- `make dp` builds the DP roofline plot.
- `make clean` removes generated files.

## Key variables

- `EXE` (required): path to the executable to profile. Prefer absolute paths.
- `FLAGS`: extra arguments passed to the executable.
- `OUT_DIR`: output directory (default: `out`).
- `KERNELS` (required): comma-separated list of kernel name substrings to include; also passed to NCU via `--kernel-name` to profile only those kernels.
- `NCU_KERNEL_NAME_BASE`: base name used by NCU for matching kernels (default: `demangled`).
- `METRICSFILE`: path to the metrics list (default: `METRICS`).
- `ROOFLINE_PRECISION`: peak selection for roofline (`fp` or `dp`, default: `fp`).
- `NCU_RUNS`: number of NCU runs to capture (default: `1`).
- `NCU_WARMUP`: number of initial runs to discard when averaging (default: `0`).

Example:

```sh
make EXE=/home/user/bin/my_app FLAGS="--size 1024" OUT_DIR=build KERNELS=kernelA,kernelB
```

## How data flows

1. `ncu --page raw --metrics=$(METRICS)` writes `out/profile.raw.<run>` for each run.
2. `ncu2dat` generates a single `out/profile.dat` that includes all plot variables and an `instmix` data block, averaging over runs after warmup discard.
3. Gnuplot renders `.ps`, then `ps2pdf` produces the final PDFs.

If you need to re-capture profiling data, remove `out/profile.raw` or run
`make clean`.
