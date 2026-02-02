EXE ?= ./a.out
FLAGS ?=
KERNELS ?=
OUT_DIR ?= out
WORKLOAD ?= profile
SOC ?=
PROFILER ?= rocprof-compute
PROFILER_ARGS ?=
PROFILER_CMD ?= $(PROFILER) profile --name $(WORKLOAD) $(PROFILER_ARGS) -- $(EXE) $(FLAGS)
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

clean:
	@rm -f $(DATA_FILE) $(ROOFLINE_PLOT)
