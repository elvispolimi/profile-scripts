# H100 PCIe (114 SMs), using an "effective" clock that matches the published 24 TFLOPS FP64 peak
# (Clock implied by datasheet peak: clock = 24,000 / (114*64*2) ≈ 1.6447 GHz)
PEAK       = 114*64*2*1.6447 # = ~24,000 GFLOP/s (== 24 TFLOPS FP64, FMA counted as 2)
PEAK_NOFMA = $(PEAK)/2

# HBM peak bandwidth from datasheet: 2 TB/s
HBM_PEAK   = 62.5*32         # = 2000 GB/s  (== 2 TB/s)

# 22.6 TiB/s = 22.6*1024 = 23142 GiB/s
L1_PEAK = 723.2*32        # ≈ 23142 GiB/s  (~22.6 TiB/s)

# 23.3 TiB/s = 23.3*1024 = 23839 GiB/s
SMEM_PEAK = 744.97*32     # ≈ 23839 GiB/s  (~23.3 TiB/s)

# 6919 GB/s
L2_PEAK = 216.22*32       # ≈ 6919 GB/s
