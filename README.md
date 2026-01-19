# profile-nvidia-scripts

Make-based pipeline to profile a single executable with Nsight Compute (ncu),
convert metrics into gnuplot variables, and generate roofline and instruction
mix plots. All plots share the same `ncu` capture and CSV so you only profile
once per run.

## Quick start

Run the executable and build all plots:

```sh
make EXE=/absolute/path/to/your/exe
```

Outputs are written under `out/` by default:

- `out/roofline-fp.pdf`
- `out/roofline-inst.pdf`
- `out/instmix.pdf`

## Targets

- `make` builds all plots.
- `make fp` builds only the FP roofline.
- `make inst` builds only the instruction roofline.
- `make instmix` builds only the instruction mix histogram.
- `make clean` removes generated files.

## Key variables

- `EXE` (required): path to the executable to profile. Prefer absolute paths.
- `FLAGS`: extra arguments passed to the executable.
- `OUT_DIR`: output directory (default: `out`).
- `GPU`: GPU model for FP roofline parameters (default: `default`).
- `GPU_INST`: GPU model for instruction roofline parameters (default: `GPU`).

Example:

```sh
make EXE=/home/user/bin/my_app FLAGS="--size 1024" OUT_DIR=build GPU=a100
```

## GPU configs

FP roofline parameters are loaded from `gpus/<GPU>.mk` if present. The file
can define:

```
PEAK=...
L1_PEAK=...
L2_PEAK=...
HBM_PEAK=...
PEAK_NOFMA=...
```

Instruction roofline parameters can be defined in `gpus/<GPU>.inst.mk`:

```
INST_PEAK=...
INST_L1_PEAK=...
INST_L2_PEAK=...
INST_HBM_PEAK=...
```

Avoid spaces inside numeric expressions (e.g., `80*32*2*1.53`) so Make
passes values correctly to gnuplot.

## How data flows

1. `ncu` runs once and writes `out/profile.ncu`.
2. The CSV is cleaned into `out/profile.csv`.
3. Each plot generates its own `.dat` using `ncu2gnuplot`:
   - `out/roofline-fp.dat` and `out/roofline-inst.dat` use `gnuplot.template`.
   - `out/instmix.dat` uses `instmix.gnuplot.template`.
4. Gnuplot renders `.ps`, then `ps2pdf` produces the final PDFs.

If you need to re-capture profiling data, remove `out/profile.ncu` and
`out/profile.csv` or run `make clean`.
