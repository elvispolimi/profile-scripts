#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  ./profile.sh [VAR=VALUE ...] [targets...]

Targets:
  all (default)  Build all plots
  dat            Generate profile.dat only
  fp             Build SP roofline
  dp             Build DP roofline
  inst           Build instruction roofline
  shared         Build shared memory roofline
  instmix         Build instruction mix histogram
  occupancy       Build occupancy histogram
  predication     Build thread efficiency/predication histogram
  clean           Remove generated files

Variables (same names as old Makefile):
  EXE (required)                     Executable to profile
  FLAGS                             Extra args passed to EXE
  OUT_DIR (default: out)             Output directory
  KERNELS (required)                 Comma-separated kernel substrings
  ARCH (default: 80)                 GPU compute capability
  NCU (default: ncu)                 Nsight Compute binary
  GNUPLOT (default: gnuplot)         Gnuplot binary
  PSTOPDF (default: ps2pdf)          ps2pdf binary
  METRICSFILE (default: METRICS)     Metrics list file
  NCU2DAT_ARGS                       Extra args passed to ncu2dat
  ROOFLINE_PRECISION (default: fp)   fp or dp
  NCU_RUNS (default: 1)              Number of NCU runs
  NCU_WARMUP (default: 0)            Warmup runs to discard
  NCU_KERNEL_NAME_BASE (default: demangled)
  FORCE (default: 0)                 Force re-profiling even if stamp exists

Examples:
  ./profile.sh EXE=/abs/path/to/a.out KERNELS=kernelA,kernelB
  ./profile.sh OUT_DIR=/tmp/out fp inst
EOF
}

targets=()
for arg in "$@"; do
  case "$arg" in
    *=*)
      export "$arg"
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      targets+=("$arg")
      ;;
  esac
done

if [ ${#targets[@]} -eq 0 ]; then
  targets=(all)
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

EXE="${EXE:-}"
FLAGS="${FLAGS:-}"
OUT_DIR="${OUT_DIR:-out}"
KERNELS="${KERNELS:-}"
ARCH="${ARCH:-80}"
NCU="${NCU:-ncu}"
GNUPLOT="${GNUPLOT:-gnuplot}"
PSTOPDF="${PSTOPDF:-ps2pdf}"
METRICSFILE="${METRICSFILE:-${SCRIPT_DIR}/METRICS}"
NCU2DAT_ARGS="${NCU2DAT_ARGS:-}"
ROOFLINE_PRECISION="${ROOFLINE_PRECISION:-fp}"
NCU_RUNS="${NCU_RUNS:-1}"
NCU_WARMUP="${NCU_WARMUP:-0}"
NCU_KERNEL_NAME_BASE="${NCU_KERNEL_NAME_BASE:-demangled}"
FORCE="${FORCE:-0}"

comma=","

if [ -n "$KERNELS" ]; then
  KERNELS_REGEX="${KERNELS//${comma}/|}"
  NCU_KERNELS_ARG=(--kernel-name "regex:${KERNELS_REGEX}" --kernel-name-base "${NCU_KERNEL_NAME_BASE}")
else
  NCU_KERNELS_ARG=()
fi

if [ "$ARCH" = "90" ]; then
  L1_PEAK_METRIC="l1tex__lsu_writeback_active_mem_lgds.sum.peak_sustained"
  L1_PER_SECOND_METRIC="l1tex__lsu_writeback_active_mem_lgds.sum.per_second"
elif [[ "$ARCH" =~ ^(75|80|86|87|88|89)$ ]]; then
  L1_PEAK_METRIC="l1tex__lsu_writeback_active_mem_lg.sum.peak_sustained"
  L1_PER_SECOND_METRIC="l1tex__lsu_writeback_active_mem_lg.sum.per_second"
else
  L1_PEAK_METRIC="l1tex__lsu_writeback_active.sum.peak_sustained"
  L1_PER_SECOND_METRIC="l1tex__lsu_writeback_active.sum.per_second"
fi

build_metrics_list() {
  local base
  base="$(
    awk -F'#' '{print $1}' "$METRICSFILE" | \
      grep -v -e l1tex__lsu_writeback_active_mem_lgds.sum.peak_sustained \
               -e l1tex__lsu_writeback_active_mem_lg.sum.peak_sustained \
               -e l1tex__lsu_writeback_active.sum.peak_sustained \
               -e l1tex__lsu_writeback_active_mem_lgds.sum.per_second \
               -e l1tex__lsu_writeback_active_mem_lg.sum.per_second \
               -e l1tex__lsu_writeback_active.sum.per_second | \
      xargs | tr ' ' ','
  )"
  echo "${base},${L1_PEAK_METRIC},${L1_PER_SECOND_METRIC}"
}

ensure_out_dir() {
  mkdir -p "$OUT_DIR"
}

RAW_FILE_PREFIX="${OUT_DIR}/profile.raw"
RAW_FILE_STAMP="${OUT_DIR}/profile.raw.stamp"
DATA_FILE="${OUT_DIR}/profile.dat"

run_ncu() {
  if [ -z "$EXE" ] || [ -z "$KERNELS" ]; then
    echo "ERROR: EXE and KERNELS are required to profile." >&2
    exit 1
  fi
  ensure_out_dir
  if [ "$FORCE" != "1" ] && [ -f "$RAW_FILE_STAMP" ]; then
    return
  fi
  rm -f "${RAW_FILE_PREFIX}."* "$RAW_FILE_STAMP"
  local metrics
  metrics="$(build_metrics_list)"
  local i=1
  while [ "$i" -le "$NCU_RUNS" ]; do
    "$NCU" --page raw --print-units base --metrics="${metrics}" "${NCU_KERNELS_ARG[@]}" \
      "$EXE" $FLAGS > "${RAW_FILE_PREFIX}.${i}"
    i=$((i+1))
  done
  touch "$RAW_FILE_STAMP"
}

build_dat() {
  run_ncu
  local raw_args=()
  local i=1
  while [ "$i" -le "$NCU_RUNS" ]; do
    raw_args+=(--raw="${RAW_FILE_PREFIX}.${i}")
    i=$((i+1))
  done
  ensure_out_dir
  "${SCRIPT_DIR}/ncu2dat" --template="${SCRIPT_DIR}/gnuplot.template" \
    "${raw_args[@]}" \
    --warmup="$NCU_WARMUP" \
    --kernels="$KERNELS" \
    --arch="$ARCH" \
    $NCU2DAT_ARGS > "${DATA_FILE}.tmp" && mv "${DATA_FILE}.tmp" "$DATA_FILE"
}

plot_fp() {
  build_dat
  "$GNUPLOT" -e "outfile='${OUT_DIR}/roofline-sp.ps';precision='${ROOFLINE_PRECISION}'" \
    "$DATA_FILE" "${SCRIPT_DIR}/roofline.gnuplot"
  "$PSTOPDF" "${OUT_DIR}/roofline-sp.ps" "${OUT_DIR}/roofline-sp.pdf"
}

plot_dp() {
  build_dat
  "$GNUPLOT" -e "outfile='${OUT_DIR}/roofline-dp.ps';precision='dp'" \
    "$DATA_FILE" "${SCRIPT_DIR}/roofline.gnuplot"
  "$PSTOPDF" "${OUT_DIR}/roofline-dp.ps" "${OUT_DIR}/roofline-dp.pdf"
}

plot_inst() {
  build_dat
  "$GNUPLOT" -e "outfile='${OUT_DIR}/roofline-inst.ps'" \
    "$DATA_FILE" "${SCRIPT_DIR}/roofline-inst.gnuplot"
  "$PSTOPDF" "${OUT_DIR}/roofline-inst.ps" "${OUT_DIR}/roofline-inst.pdf"
}

plot_shared() {
  build_dat
  "$GNUPLOT" -e "outfile='${OUT_DIR}/roofline-shared.ps'" \
    "$DATA_FILE" "${SCRIPT_DIR}/roofline-shared.gnuplot"
  "$PSTOPDF" "${OUT_DIR}/roofline-shared.ps" "${OUT_DIR}/roofline-shared.pdf"
}

plot_instmix() {
  build_dat
  "$GNUPLOT" -e "infile='${DATA_FILE}';outfile='${OUT_DIR}/instmix.ps'" \
    "${SCRIPT_DIR}/instmix.hist.gnuplot"
  "$PSTOPDF" "${OUT_DIR}/instmix.ps" "${OUT_DIR}/instmix.pdf"
}

plot_occupancy() {
  build_dat
  "$GNUPLOT" -e "outfile='${OUT_DIR}/hist-occupancy.ps'" \
    "$DATA_FILE" "${SCRIPT_DIR}/hist-occupancy.gnuplot"
  "$PSTOPDF" "${OUT_DIR}/hist-occupancy.ps" "${OUT_DIR}/hist-occupancy.pdf"
}

plot_predication() {
  build_dat
  "$GNUPLOT" -e "outfile='${OUT_DIR}/hist-predication.ps'" \
    "$DATA_FILE" "${SCRIPT_DIR}/hist-predication.gnuplot"
  "$PSTOPDF" "${OUT_DIR}/hist-predication.ps" "${OUT_DIR}/hist-predication.pdf"
}

clean() {
  rm -f \
    "${OUT_DIR}/roofline-sp.pdf" \
    "${OUT_DIR}/roofline-dp.pdf" \
    "${OUT_DIR}/roofline-inst.pdf" \
    "${OUT_DIR}/roofline-shared.pdf" \
    "${OUT_DIR}/instmix.pdf" \
    "${OUT_DIR}/hist-occupancy.pdf" \
    "${OUT_DIR}/hist-predication.pdf" \
    "${OUT_DIR}/roofline-sp.ps" \
    "${OUT_DIR}/roofline-dp.ps" \
    "${OUT_DIR}/roofline-inst.ps" \
    "${OUT_DIR}/roofline-shared.ps" \
    "${OUT_DIR}/instmix.ps" \
    "${OUT_DIR}/hist-occupancy.ps" \
    "${OUT_DIR}/hist-predication.ps" \
    "${DATA_FILE}" \
    "${RAW_FILE_PREFIX}."* \
    "${RAW_FILE_STAMP}"
}

for t in "${targets[@]}"; do
  case "$t" in
    all)
      plot_fp
      plot_dp
      plot_inst
      plot_shared
      plot_instmix
      plot_occupancy
      plot_predication
      ;;
    dat)
      build_dat
      ;;
    fp)
      plot_fp
      ;;
    dp)
      plot_dp
      ;;
    inst)
      plot_inst
      ;;
    shared)
      plot_shared
      ;;
    instmix)
      plot_instmix
      ;;
    occupancy)
      plot_occupancy
      ;;
    predication)
      plot_predication
      ;;
    clean)
      clean
      ;;
    *)
      echo "Unknown target: $t" >&2
      usage
      exit 1
      ;;
  esac
done
