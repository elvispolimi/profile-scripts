EXE ?= ./a.out
FLAGS ?=
METRICSFILE     ?= METRICS
NCU             ?= ncu
GNUPLOT         ?= gnuplot
PSTOPDF         ?= ps2pdf
OUT_DIR         ?= out
GPU             ?= default
GPU_CONFIG      := gpus/$(GPU).mk
GPU_INST        ?= $(GPU)
GPU_INST_CONFIG := gpus/$(GPU_INST).inst.mk

ifneq ("$(wildcard $(GPU_CONFIG))","")
include $(GPU_CONFIG)
else
$(warning GPU config '$(GPU_CONFIG)' not found; using gnuplot defaults)
endif

ifneq ("$(wildcard $(GPU_INST_CONFIG))","")
include $(GPU_INST_CONFIG)
endif

GNUPLOT_VARS :=
ifdef PEAK
GNUPLOT_VARS += peak=$(PEAK)
endif
ifdef L1_PEAK
GNUPLOT_VARS += l1_peak=$(L1_PEAK)
endif
ifdef L2_PEAK
GNUPLOT_VARS += l2_peak=$(L2_PEAK)
endif
ifdef HBM_PEAK
GNUPLOT_VARS += hbm_peak=$(HBM_PEAK)
endif
ifdef PEAK_NOFMA
GNUPLOT_VARS += peak_nofma=$(PEAK_NOFMA)
endif
GNUPLOT_VARS_SEMI := $(foreach v,$(GNUPLOT_VARS),$(v);)

GNUPLOT_INST_VARS :=
ifdef INST_PEAK
GNUPLOT_INST_VARS += peak=$(INST_PEAK)
endif
ifdef INST_L1_PEAK
GNUPLOT_INST_VARS += l1_peak=$(INST_L1_PEAK)
endif
ifdef INST_L2_PEAK
GNUPLOT_INST_VARS += l2_peak=$(INST_L2_PEAK)
endif
ifdef INST_HBM_PEAK
GNUPLOT_INST_VARS += hbm_peak=$(INST_HBM_PEAK)
endif
GNUPLOT_INST_VARS_SEMI := $(foreach v,$(GNUPLOT_INST_VARS),$(v);)

.PRECIOUS: $(OUT_DIR)/%.ps $(OUT_DIR)/%.pdf $(OUT_DIR)/%.dat $(OUT_DIR)/%.csv $(OUT_DIR)/%.ncu

METRICS = $(shell cut -f1 -d\# $(METRICSFILE) | xargs | tr ' ' ',')

# Expected files:
# pdf plots
ROOFLINE_FP_PLOTS ?=
ROOFLINE_FP_PLOTS += roofline-fp
ROOFLINE_INST_PLOTS ?=
ROOFLINE_INST_PLOTS += roofline-inst
INSTMIX_PLOTS ?=
INSTMIX_PLOTS += instmix

PLOT_NAMES = $(ROOFLINE_FP_PLOTS) $(ROOFLINE_INST_PLOTS) $(INSTMIX_PLOTS)

PLOTS = $(addprefix $(OUT_DIR)/,$(addsuffix .pdf,$(PLOT_NAMES)))
# ps plots
PS_FILES = $(patsubst %.pdf, %.ps, $(PLOTS))
# gnuplot data files
DAT_FILES = $(patsubst %.pdf, %.dat, $(PLOTS))
# nsight raw output (single capture shared by all plots)
NCU_FILE = $(OUT_DIR)/profile.ncu
# csv from cleaned up nsight output files
CSV_FILE = $(OUT_DIR)/profile.csv

.PRECIOUS: $(NCU_FILE)

all: $(PLOTS)
dat: $(DAT_FILES)
csv: $(CSV_FILE)
fp: $(addprefix $(OUT_DIR)/,$(addsuffix .pdf,$(ROOFLINE_FP_PLOTS)))
inst: $(addprefix $(OUT_DIR)/,$(addsuffix .pdf,$(ROOFLINE_INST_PLOTS)))
instmix: $(addprefix $(OUT_DIR)/,$(addsuffix .pdf,$(INSTMIX_PLOTS)))

$(OUT_DIR):
	mkdir -p $@

$(NCU_FILE): | $(OUT_DIR)
	$(NCU) --csv --metrics=$(METRICS) $(EXE) $(FLAGS) > $@

$(CSV_FILE): $(NCU_FILE)
	sed -e '/==PROF==/,/==PROF==/d' $< > $@

$(OUT_DIR)/roofline-fp.dat: $(CSV_FILE)
	./ncu2gnuplot --template=gnuplot.template --input=$< > $@

$(OUT_DIR)/roofline-inst.dat: $(CSV_FILE)
	./ncu2gnuplot --template=gnuplot.template --input=$< > $@

$(OUT_DIR)/instmix.dat: $(CSV_FILE)
	./ncu2gnuplot --template=instmix.gnuplot.template --input=$< > $@

$(OUT_DIR)/roofline-fp.ps: roofline-fp.gnuplot $(OUT_DIR)/roofline-fp.dat
	$(GNUPLOT) -e "outfile='$@';$(GNUPLOT_VARS_SEMI)" $(OUT_DIR)/roofline-fp.dat $<

$(OUT_DIR)/roofline-inst.ps: roofline-inst.gnuplot $(OUT_DIR)/roofline-inst.dat
	$(GNUPLOT) -e "outfile='$@';$(GNUPLOT_INST_VARS_SEMI)" $(OUT_DIR)/roofline-inst.dat $<

$(OUT_DIR)/instmix.ps: instmix.hist.gnuplot $(OUT_DIR)/instmix.dat
	$(GNUPLOT) -e "infile='$(OUT_DIR)/instmix.dat';outfile='$@'" instmix.hist.gnuplot

$(OUT_DIR)/%.pdf: $(OUT_DIR)/%.ps
	$(PSTOPDF) $< $@

clean:
	@rm -f \
		$(PLOTS) \
		$(PS_FILES) \
		$(DAT_FILES) \
		$(NCU_FILE) \
		$(CSV_FILE)
