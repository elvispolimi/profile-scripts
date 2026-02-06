EXE ?= ./a.out
FLAGS ?=
METRICSFILE     ?= METRICS
ARCH            ?= 80
NCU             ?= ncu
GNUPLOT         ?= gnuplot
PSTOPDF         ?= ps2pdf
OUT_DIR         ?= out
KERNELS         ?=
comma := ,
NCU_KERNEL_NAME_BASE ?= demangled
NCU2DAT_ARGS   ?=
ROOFLINE_PRECISION ?= fp
NCU_RUNS ?= 1
NCU_WARMUP ?= 0
RAW_FILE_PREFIX = $(OUT_DIR)/profile.raw
RAW_FILE_STAMP = $(OUT_DIR)/profile.raw.stamp

ifeq ($(V),1)
Q :=
else
Q := @
endif

ifneq ($(strip $(KERNELS)),)
KERNELS_REGEX := $(subst $(comma),|,$(KERNELS))
NCU_KERNELS_ARG := --kernel-name "regex:$(KERNELS_REGEX)" --kernel-name-base $(NCU_KERNEL_NAME_BASE)
endif

.PRECIOUS: $(OUT_DIR)/%.ps $(OUT_DIR)/%.pdf $(OUT_DIR)/%.dat

ifeq ($(ARCH),90)
L1_PEAK_METRIC := l1tex__lsu_writeback_active_mem_lgds.sum.peak_sustained
L1_PER_SECOND_METRIC := l1tex__lsu_writeback_active_mem_lgds.sum.per_second
else ifneq (,$(filter 75 80 86 87 88 89,$(ARCH)))
L1_PEAK_METRIC := l1tex__lsu_writeback_active_mem_lg.sum.peak_sustained
L1_PER_SECOND_METRIC := l1tex__lsu_writeback_active_mem_lg.sum.per_second
else
L1_PEAK_METRIC := l1tex__lsu_writeback_active.sum.peak_sustained
L1_PER_SECOND_METRIC := l1tex__lsu_writeback_active.sum.per_second
endif

METRICS_BASE = $(shell cut -f1 -d\# $(METRICSFILE) | \
	grep -v -e l1tex__lsu_writeback_active_mem_lgds.sum.peak_sustained \
	         -e l1tex__lsu_writeback_active_mem_lg.sum.peak_sustained \
	         -e l1tex__lsu_writeback_active.sum.peak_sustained \
	         -e l1tex__lsu_writeback_active_mem_lgds.sum.per_second \
	         -e l1tex__lsu_writeback_active_mem_lg.sum.per_second \
	         -e l1tex__lsu_writeback_active.sum.per_second | \
	xargs | tr ' ' ',')
METRICS = $(METRICS_BASE),$(L1_PEAK_METRIC),$(L1_PER_SECOND_METRIC)

# Expected files:
# pdf plots
ROOFLINE_SP_PLOTS ?=
ROOFLINE_SP_PLOTS += roofline-sp
ROOFLINE_DP_PLOTS ?=
ROOFLINE_DP_PLOTS += roofline-dp
ROOFLINE_INST_PLOTS ?=
ROOFLINE_INST_PLOTS += roofline-inst
INSTMIX_PLOTS ?=
INSTMIX_PLOTS += instmix

PLOT_NAMES = $(ROOFLINE_SP_PLOTS) $(ROOFLINE_DP_PLOTS) $(ROOFLINE_INST_PLOTS) $(INSTMIX_PLOTS)

PLOTS = $(addprefix $(OUT_DIR)/,$(addsuffix .pdf,$(PLOT_NAMES)))
# ps plots
PS_FILES = $(patsubst %.pdf, %.ps, $(PLOTS))
# gnuplot data file
DATA_FILE = $(OUT_DIR)/profile.dat
RAW_RUNS = $(shell seq 1 $(NCU_RUNS))
RAW_FILES = $(addprefix $(RAW_FILE_PREFIX)., $(RAW_RUNS))
DAT_FILES = $(DATA_FILE)
all: $(PLOTS)
dat: $(DATA_FILE)
fp: $(addprefix $(OUT_DIR)/,$(addsuffix .pdf,$(ROOFLINE_SP_PLOTS)))
inst: $(addprefix $(OUT_DIR)/,$(addsuffix .pdf,$(ROOFLINE_INST_PLOTS)))
instmix: $(addprefix $(OUT_DIR)/,$(addsuffix .pdf,$(INSTMIX_PLOTS)))
dp: $(addprefix $(OUT_DIR)/,$(addsuffix .pdf,$(ROOFLINE_DP_PLOTS)))

$(OUT_DIR):
	mkdir -p $@

$(RAW_FILE_STAMP): | $(OUT_DIR)
	$(Q)rm -f $(RAW_FILES)
	$(Q)i=1; while [ $$i -le $(NCU_RUNS) ]; do \
		$(NCU) --page raw --metrics=$(METRICS) $(NCU_KERNELS_ARG) $(EXE) $(FLAGS) > $(RAW_FILE_PREFIX).$$i; \
		i=$$((i+1)); \
	done
	$(Q)touch $@

$(DATA_FILE): $(RAW_FILE_STAMP)
	$(Q)./ncu2dat --template=gnuplot.template $(addprefix --raw=,$(RAW_FILES)) --warmup=$(NCU_WARMUP) --kernels="$(KERNELS)" --arch=$(ARCH) $(NCU2DAT_ARGS) > $@.tmp && mv $@.tmp $@

$(OUT_DIR)/roofline-sp.ps: roofline.gnuplot $(DATA_FILE)
	$(Q)$(GNUPLOT) -e "outfile='$@';precision='$(ROOFLINE_PRECISION)'" $(DATA_FILE) $<

$(OUT_DIR)/roofline-dp.ps: roofline.gnuplot $(DATA_FILE)
	$(Q)$(GNUPLOT) -e "outfile='$@';precision='dp'" $(DATA_FILE) $<

$(OUT_DIR)/roofline-inst.ps: roofline-inst.gnuplot $(DATA_FILE)
	$(Q)$(GNUPLOT) -e "outfile='$@'" $(DATA_FILE) $<

$(OUT_DIR)/instmix.ps: instmix.hist.gnuplot $(DATA_FILE)
	$(Q)$(GNUPLOT) -e "infile='$(DATA_FILE)';outfile='$@'" instmix.hist.gnuplot

$(OUT_DIR)/%.pdf: $(OUT_DIR)/%.ps
	$(Q)$(PSTOPDF) $< $@

clean:
	$(Q)rm -f \
		$(PLOTS) \
		$(PS_FILES) \
		$(DAT_FILES) \
		$(RAW_FILES) \
		$(RAW_FILE_STAMP)
