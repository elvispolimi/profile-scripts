#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  ./profile.sh [VAR=VALUE ...] [targets...]

Targets:
  all (default)  Build all plots
  profile         Run the profiler
  dat             Generate profile.dat only
  plot            Build roofline plot (SP/FP32 by default)
  fp              Build SP/FP32 roofline
  dp              Build DP/FP64 roofline
  int             Build INT32 roofline
  inst            Build instruction roofline
  shared          Build shared/LDS roofline
  instmix         Build instruction mix plot
  occupancy       Build occupancy histogram
  predication     Build thread efficiency histogram
  clean           Remove generated files

Variables (same names as old Makefile):
  EXE (required for profile)         Executable to profile
  FLAGS                             Extra args passed to EXE
  KERNELS                           Comma-separated kernel substrings (empty means all kernels)
  OUT_DIR (default: out)            Output directory
  WORKLOAD (default: profile)       Profiler workload name
  SOC                               Explicit SOC directory under workloads/WORKLOAD
  PROFILER (default: rocprof-compute)
  PROFILER_ARGS                     Extra profiler args (e.g., device selection)
  ROOF_ONLY (default: 1)            0 for full profiling
  ROOFLINE_DATA_TYPE (default: FP32)
  PROFILER_CMD                      Full command override
  AMD2DAT (default: ./omniperf2dat)
  AMD2DAT_ARGS                      Extra args passed to omniperf2dat
  GNUPLOT (default: gnuplot)
  PSTOPDF (default: ps2pdf)
  ROOFLINE_PRECISION (default: fp32) fp32, fp64, or int32

Examples:
  ./profile.sh profile EXE=/path/to/your/exe KERNELS=kernelA,kernelB
  ./profile.sh OUT_DIR=/tmp/out plot
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
KERNELS="${KERNELS:-}"
OUT_DIR="${OUT_DIR:-out}"
WORKLOAD="${WORKLOAD:-profile}"
SOC="${SOC:-}"
PROFILER="${PROFILER:-rocprof-compute}"
PROFILER_ARGS="${PROFILER_ARGS:-}"
ROOF_ONLY="${ROOF_ONLY:-1}"
ROOFLINE_DATA_TYPE="${ROOFLINE_DATA_TYPE:-FP32}"
PROFILER_CMD="${PROFILER_CMD:-}"
AMD2DAT="${AMD2DAT:-${SCRIPT_DIR}/omniperf2dat}"
AMD2DAT_ARGS="${AMD2DAT_ARGS:-}"
GNUPLOT="${GNUPLOT:-gnuplot}"
PSTOPDF="${PSTOPDF:-ps2pdf}"
ROOFLINE_PRECISION="${ROOFLINE_PRECISION:-fp32}"

comma=","
KERNELS_ARG=()
if [ -n "$KERNELS" ]; then
  IFS=',' read -r -a _kernels <<<"$KERNELS"
  for k in "${_kernels[@]}"; do
    if [ -n "$k" ]; then
      KERNELS_ARG+=(-k "$k")
    fi
  done
fi

ROOF_ONLY_ARG=()
if [ "${ROOF_ONLY}" != "0" ]; then
  ROOF_ONLY_ARG+=(--roof-only)
fi

WORKLOAD_DIR="${SCRIPT_DIR}/workloads/${WORKLOAD}"
if [ -n "$SOC" ]; then
  WORKLOAD_PATH="${WORKLOAD_DIR}/${SOC}"
else
  WORKLOAD_PATH="$(ls -d "${WORKLOAD_DIR}"/* 2>/dev/null | head -n 1 || true)"
fi

DATA_FILE="${OUT_DIR}/profile.dat"
ROOFLINE_SP_PS="${OUT_DIR}/roofline-fp32.ps"
ROOFLINE_SP_PDF="${OUT_DIR}/roofline-fp32.pdf"
ROOFLINE_DP_PS="${OUT_DIR}/roofline-fp64.ps"
ROOFLINE_DP_PDF="${OUT_DIR}/roofline-fp64.pdf"
ROOFLINE_INT_PS="${OUT_DIR}/roofline-int32.ps"
ROOFLINE_INT_PDF="${OUT_DIR}/roofline-int32.pdf"
ROOFLINE_INST_PS="${OUT_DIR}/roofline-inst.ps"
ROOFLINE_INST_PDF="${OUT_DIR}/roofline-inst.pdf"
ROOFLINE_SHARED_PS="${OUT_DIR}/roofline-shared.ps"
ROOFLINE_SHARED_PDF="${OUT_DIR}/roofline-shared.pdf"
INSTMIX_PS="${OUT_DIR}/instmix.ps"
INSTMIX_PDF="${OUT_DIR}/instmix.pdf"
OCCUPANCY_PS="${OUT_DIR}/hist-occupancy.ps"
OCCUPANCY_PDF="${OUT_DIR}/hist-occupancy.pdf"
PREDICATION_PS="${OUT_DIR}/hist-predication.ps"
PREDICATION_PDF="${OUT_DIR}/hist-predication.pdf"

ensure_out_dir() {
  mkdir -p "$OUT_DIR"
}

run_profiler() {
  if [ -z "$EXE" ]; then
    echo "ERROR: EXE is required for profile target." >&2
    exit 1
  fi
  pushd "$SCRIPT_DIR" >/dev/null
  if [ -n "$PROFILER_CMD" ]; then
    bash -c "$PROFILER_CMD"
  else
    "$PROFILER" profile --name "$WORKLOAD" \
      "${ROOF_ONLY_ARG[@]}" \
      --roofline-data-type "$ROOFLINE_DATA_TYPE" \
      "${KERNELS_ARG[@]}" \
      ${PROFILER_ARGS} -- "$EXE" $FLAGS
  fi
  popd >/dev/null
}

build_dat() {
  if [ -z "$WORKLOAD_PATH" ] || [ ! -d "$WORKLOAD_PATH" ]; then
    echo "ERROR: workload path not found: ${WORKLOAD_PATH:-<empty>}" >&2
    echo "Run profile first or set WORKLOAD/SOC." >&2
    exit 1
  fi
  ensure_out_dir
  "$AMD2DAT" --workload "$WORKLOAD_PATH" --kernels "$KERNELS" --precision "$ROOFLINE_PRECISION" \
    $AMD2DAT_ARGS \
    > "${DATA_FILE}.tmp" && mv "${DATA_FILE}.tmp" "$DATA_FILE"
}

plot_fp() {
  build_dat
  "$GNUPLOT" -e "outfile='${ROOFLINE_SP_PS}';precision='fp'" \
    "$DATA_FILE" "${SCRIPT_DIR}/roofline.gnuplot"
  "$PSTOPDF" "${ROOFLINE_SP_PS}" "${ROOFLINE_SP_PDF}"
}

plot_roofline() {
  case "${ROOFLINE_PRECISION}" in
    fp64|dp) plot_dp ;;
    int32|int) plot_int ;;
    *) plot_fp ;;
  esac
}

plot_dp() {
  build_dat
  "$GNUPLOT" -e "outfile='${ROOFLINE_DP_PS}';precision='dp'" \
    "$DATA_FILE" "${SCRIPT_DIR}/roofline.gnuplot"
  "$PSTOPDF" "${ROOFLINE_DP_PS}" "${ROOFLINE_DP_PDF}"
}

plot_int() {
  build_dat
  "$GNUPLOT" -e "outfile='${ROOFLINE_INT_PS}';precision='int'" \
    "$DATA_FILE" "${SCRIPT_DIR}/roofline.gnuplot"
  "$PSTOPDF" "${ROOFLINE_INT_PS}" "${ROOFLINE_INT_PDF}"
}

plot_inst() {
  build_dat
  "$GNUPLOT" -e "outfile='${ROOFLINE_INST_PS}'" \
    "$DATA_FILE" "${SCRIPT_DIR}/roofline-inst.gnuplot"
  "$PSTOPDF" "${ROOFLINE_INST_PS}" "${ROOFLINE_INST_PDF}"
}

plot_shared() {
  build_dat
  "$GNUPLOT" -e "outfile='${ROOFLINE_SHARED_PS}'" \
    "$DATA_FILE" "${SCRIPT_DIR}/roofline-shared.gnuplot"
  "$PSTOPDF" "${ROOFLINE_SHARED_PS}" "${ROOFLINE_SHARED_PDF}"
}

plot_instmix() {
  build_dat
  "$GNUPLOT" -e "infile='${DATA_FILE}';outfile='${INSTMIX_PS}'" \
    "${SCRIPT_DIR}/instmix.hist.gnuplot"
  "$PSTOPDF" "${INSTMIX_PS}" "${INSTMIX_PDF}"
}

plot_occupancy() {
  build_dat
  "$GNUPLOT" -e "outfile='${OCCUPANCY_PS}'" \
    "$DATA_FILE" "${SCRIPT_DIR}/hist-occupancy.gnuplot"
  "$PSTOPDF" "${OCCUPANCY_PS}" "${OCCUPANCY_PDF}"
}

plot_predication() {
  build_dat
  "$GNUPLOT" -e "outfile='${PREDICATION_PS}'" \
    "$DATA_FILE" "${SCRIPT_DIR}/hist-predication.gnuplot"
  "$PSTOPDF" "${PREDICATION_PS}" "${PREDICATION_PDF}"
}

clean() {
  rm -f \
    "$DATA_FILE" \
    "$ROOFLINE_SP_PS" "$ROOFLINE_SP_PDF" \
    "$ROOFLINE_DP_PS" "$ROOFLINE_DP_PDF" \
    "$ROOFLINE_INT_PS" "$ROOFLINE_INT_PDF" \
    "$ROOFLINE_INST_PS" "$ROOFLINE_INST_PDF" \
    "$ROOFLINE_SHARED_PS" "$ROOFLINE_SHARED_PDF" \
    "$INSTMIX_PS" "$INSTMIX_PDF" \
    "$OCCUPANCY_PS" "$OCCUPANCY_PDF" \
    "$PREDICATION_PS" "$PREDICATION_PDF"
}

for t in "${targets[@]}"; do
  case "$t" in
    all)
      plot_fp
      plot_dp
      plot_int
      plot_inst
      plot_shared
      plot_instmix
      plot_occupancy
      plot_predication
      ;;
    profile)
      run_profiler
      ;;
    dat)
      build_dat
      ;;
    plot)
      plot_roofline
      ;;
    fp)
      plot_fp
      ;;
    dp)
      plot_dp
      ;;
    int|int32)
      plot_int
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
