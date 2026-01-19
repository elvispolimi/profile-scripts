# A100 (GA100) — using SXM  boost clock = 1.410 GHz
PEAK        = 108*32*2*1.410          # = ~9.75  TFLOPS (FP64, counting FMA as 2)
PEAK_NOFMA  = $(PEAK)/2               # = ~4.87  TFLOPS (FP64, counting FMA as 1)

# If you want FP64 Tensor Core peak (A100 supports FP64 on tensor cores too):
PEAK_FP64_TC       = 108*64*2*1.410   # = ~19.5 TFLOPS (FP64 Tensor Core, counting FMA as 2)
PEAK_FP64_TC_NOFMA = $(PEAK_FP64_TC)/2

# A100 80GB SXM (HBM2e): 2039 GB/s
HBM_PEAK = 63.71875*32  # (=2039)

# https://www.nvidia.com/en-us/on-demand/session/gtcspring21-s33322/
# 18 TiB/s = 18*1024 = 18432 GiB/s
L1_PEAK  = 576*32          # = 18432 GiB/s  (== 18 TiB/s)

# 7050 GB/s (already decimal GB)
L2_PEAK  = 220.3125*32     # = 7050 GB/s

