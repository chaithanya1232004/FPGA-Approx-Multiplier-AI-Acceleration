import numpy as np

def fuse_conv_and_bn(weights, bias, gamma, beta, mean, var, eps=1e-5, scale=256):
    """
    Folds Batch Normalization parameters into Convolution Weights and Bias.
    weights : shape (3, 3) - original Conv kernel
    bias    : float        - original Conv bias
    gamma, beta, mean, var : BN trained parameters
    scale   : fixed-point Q8.8 scaling factor (256)
    """
    # 1. Compute scaling factor: alpha = gamma / sqrt(variance + epsilon)
    std = np.sqrt(var + eps)
    alpha = gamma / std
    
    # 2. Compute Fused Weight: W_fused = W * alpha
    fused_weights = weights * alpha
    
    # 3. Compute Fused Bias: B_fused = alpha * (bias - mean) + beta
    fused_bias = alpha * (bias - mean) + beta
    
    # 4. Quantize to 16-bit Fixed-Point Integers (Q8.8 format, scale = 256)
    fused_weights_fixed = np.round(fused_weights * scale).astype(np.int16)
    fused_bias_fixed    = np.round(fused_bias * scale).astype(np.int16)
    
    return fused_weights, fused_bias, fused_weights_fixed, fused_bias_fixed

# ==============================================================================
# DEMONSTRATION WITH TYPICAL CNN WEIGHTS AND BATCH-NORM PARAMETERS
# ==============================================================================
print("="*65)
print("   FUSED CONV + BATCH-NORMALIZATION + ReLU OFFLINE OPTIMIZER    ")
print("="*65)

# A sample 3x3 trained edge kernel
W_orig = np.array([
    [-1.0,  0.0,  1.0],
    [-2.0,  0.0,  2.0],
    [-1.0,  0.0,  1.0]
])
B_orig = 0.5

# Typical trained Batch-Normalization parameters from PyTorch / TensorFlow
gamma = 1.25   # BN Scale
beta  = 0.15   # BN Shift / Offset
mean  = 0.08   # Running Mean
var   = 0.04   # Running Variance

# Run the fusion
W_float, B_float, W_fpga, B_fpga = fuse_conv_and_bn(W_orig, B_orig, gamma, beta, mean, var)

print("\n1. Original Floating-Point Kernel (Before Fusion):")
print(W_orig)

print("\n2. Mathematically Fused Floating-Point Kernel (Conv + BN):")
print(np.round(W_float, 4))
print(f"Fused Floating-Point Bias: {B_float:.4f}")

print("\n" + "-"*65)
print("3. FINAL QUANTIZED 16-BIT INTEGER WEIGHTS FOR FPGA (Q8.8 Format):")
print("-"*65)
print(W_fpga)
print(f"\nFinal Quantized 16-bit Bias for FPGA: {B_fpga}")
print("="*65)

print("\n[VERIFICATION]: How to use this in your Verilog Testbench:")
print("In tb_cnn_conv_engine.v, set the kernel weights directly to:")
for r in range(3):
    for c in range(3):
        print(f"conv_kernel[{r*3 + c}] = 16'sd{W_fpga[r, c]}; ", end="")
    print()
print(f"bias_in = 16'sd{B_fpga};")
print("="*65)