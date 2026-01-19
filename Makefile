EXE ?= test_cswgs
FOLDER_EXE ?= /home/gaccordi/repo/streamOI_CGH/libselholo/build/
FLAGS ?=  ""
METRICSFILE     ?= METRICS
NCU             ?= ncu
GNUPLOT         ?= gnuplot
PSTOPDF         ?= ps2pdf

.PRECIOUS: %.ps %.pdf %.dat %.csv %.ncu

METRICS = $(shell cut -f1 -d\# $(METRICSFILE) | xargs | tr ' ' ',')

# Expected files:
# pdf plots
PLOTS =
PLOTS += roofline-fp.pdf
# ps plots
PS_FILES = $(patsubst %.pdf, %.ps, $(PLOTS))
# gnuplot data files
DAT_FILES = $(patsubst %.pdf, %.dat, $(PLOTS))
# nsight raw output
NCU_FILES =
NCU_FILES += $(patsubst %, %.ncu, $(PLOTS))
# csv from cleaned up nsight output files
CSV_FILES =
CSV_FILES += $(patsubst %, %.csv, $(PLOTS))

.PRECIOUS: $(NCU_FILES)

all: $(PLOTS)
dat: $(DAT_FILES)
csv: $(CSV_FILES)

%.ncu: 
	$(NCU) --csv --metrics=$(METRICS) $(FOLDER_EXE)/$(EXE) $(FLAGS)  > $@

%.csv: %.ncu
	sed -e '/==PROF==/,/==PROF==/d' $< > $@

%.dat: %.csv
	./ncu2gnuplot --template=gnuplot.template --input=$< > $@

%.ps: %.gnuplot %.dat
	$(GNUPLOT) -e "outfile='$@'" $*.dat $<

%.pdf: %.ps
	$(PSTOPDF) $< $@

clean:
	@rm -f \
		$(PLOTS) \
		$(PS_FILES) \
		$(DAT_FILES) \
		$(NCU_FILES) \
		$(CSV_FILES)
