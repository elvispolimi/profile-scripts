#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  ./profile.sh [VAR=VALUE ...] [targets...]

Targets:
  all (default)  Build all plots
  profile        Run Intel profiler commands and export CSV files
  dat            Generate profile.dat only
  plot           Build roofline plot (FP32 by default)
  fp             Build FP32 roofline
  dp             Build FP64 roofline
  inst           Build instruction roofline
  shared         Build shared-memory style roofline
  instmix        Build instruction mix histogram
  occupancy      Build occupancy histogram
  predication    Build predication/thread efficiency histogram
  clean          Remove generated files

Variables:
  EXE (required for profile)                Executable to profile
  FLAGS                                     Extra args passed to EXE
  KERNELS (required for dat/plot targets)   Comma-separated kernel substrings
  OUT_DIR (default: out)                    Output directory
  ADVISOR (default: advisor)                Intel Advisor binary
  ADVISOR_PROJECT (default: OUT_DIR/advisor-project)
  ADVISOR_COLLECT_ARGS                      Extra args for advisor collect
  ADVISOR_REPORT_ARGS                       Extra args for advisor roofline report
  ROOFLINE_CSV (default: OUT_DIR/advisor-roofline.csv)
  METRICS_CSV (default: OUT_DIR/intel-metrics.csv)
  UNITRACE_CMD                              Optional command that generates METRICS_CSV
  PROFILER_CMD                              Full profile command override
  INTEL2DAT (default: ./intel2dat)
  INTEL2DAT_ARGS                            Extra args passed to intel2dat
  GNUPLOT (default: gnuplot)
  PSTOPDF (default: ps2pdf)
  ROOFLINE_PRECISION (default: fp)          fp or dp
  FORCE (default: 0)                        Force profiling even if CSV exists

Examples:
  ./profile.sh profile EXE=/path/to/a.out FLAGS="--size 1024"
  ./profile.sh dat KERNELS=myKernelA,myKernelB
  ./profile.sh fp KERNELS=myKernel
USAGE
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
ADVISOR="${ADVISOR:-advisor}"
ADVISOR_PROJECT="${ADVISOR_PROJECT:-${OUT_DIR}/advisor-project}"
ADVISOR_COLLECT_ARGS="${ADVISOR_COLLECT_ARGS:-}"
ADVISOR_REPORT_ARGS="${ADVISOR_REPORT_ARGS:-}"
ROOFLINE_CSV="${ROOFLINE_CSV:-${OUT_DIR}/advisor-roofline.csv}"
METRICS_CSV="${METRICS_CSV:-${OUT_DIR}/intel-metrics.csv}"
UNITRACE_CMD="${UNITRACE_CMD:-}"
PROFILER_CMD="${PROFILER_CMD:-}"
INTEL2DAT="${INTEL2DAT:-${SCRIPT_DIR}/intel2dat}"
INTEL2DAT_ARGS="${INTEL2DAT_ARGS:-}"
GNUPLOT="${GNUPLOT:-gnuplot}"
PSTOPDF="${PSTOPDF:-ps2pdf}"
ROOFLINE_PRECISION="${ROOFLINE_PRECISION:-fp}"
FORCE="${FORCE:-0}"

DATA_FILE="${OUT_DIR}/profile.dat"
ROOFLINE_SP_PS="${OUT_DIR}/roofline-sp.ps"
ROOFLINE_SP_PDF="${OUT_DIR}/roofline-sp.pdf"
ROOFLINE_DP_PS="${OUT_DIR}/roofline-dp.ps"
ROOFLINE_DP_PDF="${OUT_DIR}/roofline-dp.pdf"
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

run_profile() {
  ensure_out_dir

  if [ "$FORCE" != "1" ] && [ -f "$ROOFLINE_CSV" ]; then
    return
  fi

  if [ -n "$PROFILER_CMD" ]; then
    bash -c "$PROFILER_CMD"
  else
    if [ -z "$EXE" ]; then
      echo "ERROR: EXE is required for profile target (unless PROFILER_CMD is set)." >&2
      exit 1
    fi
    "$ADVISOR" --collect=roofline --profile-gpu --project-dir "$ADVISOR_PROJECT" \
      ${ADVISOR_COLLECT_ARGS} -- "$EXE" $FLAGS

    "$ADVISOR" --report=roofline --gpu --format=csv --project-dir "$ADVISOR_PROJECT" \
      ${ADVISOR_REPORT_ARGS} > "$ROOFLINE_CSV"
  fi

  if [ -n "$UNITRACE_CMD" ]; then
    bash -c "$UNITRACE_CMD"
  fi
}

build_dat() {
  if [ -z "$KERNELS" ]; then
    echo "ERROR: KERNELS is required for dat/plot/fp/dp/inst/shared/instmix/occupancy/predication." >&2
    exit 1
  fi
  if [ ! -f "$ROOFLINE_CSV" ]; then
    echo "ERROR: roofline CSV not found: $ROOFLINE_CSV" >&2
    echo "Run ./profile.sh profile ... first, or set ROOFLINE_CSV." >&2
    exit 1
  fi

  ensure_out_dir

  local args=(--roofline "$ROOFLINE_CSV" --kernels "$KERNELS" --precision "$ROOFLINE_PRECISION")
  if [ -f "$METRICS_CSV" ]; then
    args+=(--metrics "$METRICS_CSV")
  fi

  "$INTEL2DAT" "${args[@]}" $INTEL2DAT_ARGS > "${DATA_FILE}.tmp" && mv "${DATA_FILE}.tmp" "$DATA_FILE"
}

plot_fp() {
  build_dat
  "$GNUPLOT" -e "outfile='${ROOFLINE_SP_PS}';precision='fp'" \
    "$DATA_FILE" "${SCRIPT_DIR}/roofline.gnuplot"
  "$PSTOPDF" "${ROOFLINE_SP_PS}" "${ROOFLINE_SP_PDF}"
}

plot_dp() {
  build_dat
  "$GNUPLOT" -e "outfile='${ROOFLINE_DP_PS}';precision='dp'" \
    "$DATA_FILE" "${SCRIPT_DIR}/roofline.gnuplot"
  "$PSTOPDF" "${ROOFLINE_DP_PS}" "${ROOFLINE_DP_PDF}"
}

plot_roofline() {
  case "$ROOFLINE_PRECISION" in
    dp|fp64) plot_dp ;;
    *) plot_fp ;;
  esac
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
      plot_inst
      plot_shared
      plot_instmix
      plot_occupancy
      plot_predication
      ;;
    profile)
      run_profile
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
