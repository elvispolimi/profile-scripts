# RTX A2000 (Ampere GA10x, CC 8.6)

SM          = 26
BOOST_GHZ   = 1.2019     # implied by 8.0 TFLOPS FP32 and 3328 CUDA cores

# FP64 peak (GA10x has 2 FP64 units per SM; FP64 rate is 1/64 of FP32)
PEAK        = $(SM)*2*2*$(BOOST_GHZ)      # ≈ 0.125 TFLOPS FP64 (FMA counted as 2)
PEAK_NOFMA  = $(PEAK)/2

# Global memory peak (GDDR6, not HBM)
# MEM_PEAK    = 288                       # GB/s

# If you want the same "*32" style:
# MEM_PEAK_32 = 9*32                      # = 288 GB/s

# ~ SM * (128 B/clk/SM) * clock
# => 26*128*1.2019e9 = ~4.0e12 B/s ≈ 3725 GiB/s ≈ 3.64 TiB/s

# L1_PEAK_GiB  = 116.4*32      # ≈ 3725 GiB/s
