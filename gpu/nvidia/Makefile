EXE ?= ./a.out
FLAGS ?=
METRICSFILE     ?= METRICS
NCU             ?= ncu
GNUPLOT         ?= gnuplot
PSTOPDF         ?= ps2pdf
OUT_DIR         ?= out
KERNELS         ?=
comma := ,
NCU_KERNEL_NAME_BASE ?= demangled
ROOFLINE_PRECISION ?= fp
NCU_RUNS ?= 1
NCU_WARMUP ?= 0
RAW_FILE_PREFIX = $(OUT_DIR)/profile.raw
RAW_FILE_STAMP = $(OUT_DIR)/profile.raw.stamp

ifneq ($(strip $(KERNELS)),)
KERNELS_REGEX := $(subst $(comma),|,$(KERNELS))
NCU_KERNELS_ARG := --kernel-name "regex:$(KERNELS_REGEX)" --kernel-name-base $(NCU_KERNEL_NAME_BASE)
endif

.PRECIOUS: $(OUT_DIR)/%.ps $(OUT_DIR)/%.pdf $(OUT_DIR)/%.dat

METRICS = $(shell cut -f1 -d\# $(METRICSFILE) | xargs | tr ' ' ',')

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
	@rm -f $(RAW_FILES)
	@i=1; while [ $$i -le $(NCU_RUNS) ]; do \
		$(NCU) --page raw --metrics=$(METRICS) $(NCU_KERNELS_ARG) $(EXE) $(FLAGS) > $(RAW_FILE_PREFIX).$$i; \
		i=$$((i+1)); \
	done
	@touch $@

$(DATA_FILE): $(RAW_FILE_STAMP)
	./ncu2dat --template=gnuplot.template $(addprefix --raw=,$(RAW_FILES)) --warmup=$(NCU_WARMUP) --kernels="$(KERNELS)" > $@.tmp && mv $@.tmp $@

$(OUT_DIR)/roofline-sp.ps: roofline.gnuplot $(DATA_FILE)
	$(GNUPLOT) -e "outfile='$@';precision='$(ROOFLINE_PRECISION)'" $(DATA_FILE) $<

$(OUT_DIR)/roofline-dp.ps: roofline.gnuplot $(DATA_FILE)
	$(GNUPLOT) -e "outfile='$@';precision='dp'" $(DATA_FILE) $<

$(OUT_DIR)/roofline-inst.ps: roofline-inst.gnuplot $(DATA_FILE)
	$(GNUPLOT) -e "outfile='$@'" $(DATA_FILE) $<

$(OUT_DIR)/instmix.ps: instmix.hist.gnuplot $(DATA_FILE)
	$(GNUPLOT) -e "infile='$(DATA_FILE)';outfile='$@'" instmix.hist.gnuplot

$(OUT_DIR)/%.pdf: $(OUT_DIR)/%.ps
	$(PSTOPDF) $< $@

clean:
	@rm -f \
		$(PLOTS) \
		$(PS_FILES) \
		$(DAT_FILES) \
		$(RAW_FILES) \
		$(RAW_FILE_STAMP)
