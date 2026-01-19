# H100 SXM (132 SMs), using an "effective" clock that matches the published 30 TFLOPS FP64 peak
# (Clock implied by datasheet peak: clock = 30,000 / (132*64*2) ≈ 1.7757 GHz)
PEAK        = 132*64*2*1.7757      # = ~30,000 GFLOP/s  (== 30 TFLOPS FP64, FMA counted as 2)
PEAK_NOFMA  = $(PEAK)/2

# HBM peak bandwidth from datasheet: 3 TB/s
HBM_PEAK    = 93.75*32            # = 3000 GB/s  (== 3 TB/s)

# ~30.0 TiB/s = 30720 GiB/s
L1_PEAK = 960*32          # ≈ 30720 GiB/s

# ~30.9 TiB/s = 31650 GiB/s
SMEM_PEAK = 989.1*32      # ≈ 31650 GiB/s

# ~7933 GB/s
L2_PEAK = 247.92*32       # ≈ 7933 GB/s
