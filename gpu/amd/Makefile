EXE ?= ./a.out
FLAGS ?=
KERNELS ?=
OUT_DIR ?= out
WORKLOAD ?= profile
SOC ?=
PROFILER ?= rocprof-compute
PROFILER_ARGS ?=
ROOF_ONLY ?= 1
ROOFLINE_DATA_TYPE ?= FP32
comma := ,
ifneq ($(strip $(KERNELS)),)
KERNELS_ARG := $(foreach k,$(subst $(comma), ,$(KERNELS)),-k $(k))
endif
ifneq ($(strip $(ROOF_ONLY)),0)
ROOF_ONLY_ARG := --roof-only
endif
PROFILER_CMD ?= $(PROFILER) profile --name $(WORKLOAD) $(ROOF_ONLY_ARG) --roofline-data-type $(ROOFLINE_DATA_TYPE) $(KERNELS_ARG) $(PROFILER_ARGS) -- $(EXE) $(FLAGS)
AMD2DAT ?= ./omniperf2dat
GNUPLOT ?= gnuplot
ROOFLINE_PRECISION ?= fp32

WORKLOAD_DIR = workloads/$(WORKLOAD)
ifneq ($(strip $(SOC)),)
WORKLOAD_PATH = $(WORKLOAD_DIR)/$(SOC)
else
WORKLOAD_PATH = $(shell ls -d $(WORKLOAD_DIR)/* 2>/dev/null | head -n 1)
endif

DATA_FILE = $(OUT_DIR)/profile.dat
ROOFLINE_PLOT = $(OUT_DIR)/roofline-$(ROOFLINE_PRECISION).pdf
INSTMIX_PLOT = $(OUT_DIR)/instmix.pdf

.PHONY: all profile dat plot clean

all: $(ROOFLINE_PLOT)

profile:
	$(PROFILER_CMD)

$(OUT_DIR):
	mkdir -p $@

dat: $(DATA_FILE)

$(DATA_FILE): | $(OUT_DIR)
	$(AMD2DAT) --workload "$(WORKLOAD_PATH)" --kernels "$(KERNELS)" --precision $(ROOFLINE_PRECISION) > $@.tmp && mv $@.tmp $@

plot: $(ROOFLINE_PLOT)

$(ROOFLINE_PLOT): $(DATA_FILE) roofline.gnuplot
	$(GNUPLOT) -e "outfile='$@';precision='$(ROOFLINE_PRECISION)'" $(DATA_FILE) roofline.gnuplot

instmix: $(INSTMIX_PLOT)

$(INSTMIX_PLOT): $(DATA_FILE) instmix.hist.gnuplot
	$(GNUPLOT) -e "infile='$(DATA_FILE)';outfile='$@'" instmix.hist.gnuplot

clean:
	@rm -f $(DATA_FILE) $(ROOFLINE_PLOT) $(INSTMIX_PLOT)
