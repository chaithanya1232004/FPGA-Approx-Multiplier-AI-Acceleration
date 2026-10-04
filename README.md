# Design and Optimization of an Energy-Efficient Approximate Signed Multiplier for FPGA-Based AI Acceleration

[![FPGA](https://img.shields.io/badge/Target-Xilinx%20Virtex--7-blue.svg)](https://www.xilinx.com)
[![EDA Tool](https://img.shields.io/badge/EDA-Vivado%202026.1-red.svg)](https://www.xilinx.com/products/design-tools/vivado.html)
[![Language](https://img.shields.io/badge/Language-Verilog%20HDL%20%7C%20Python-green.svg)]()
[![License](https://img.shields.io/badge/License-MIT-yellow.svg)]()

## Overview
This repository contains the complete Verilog HDL implementation and verification environment for an **Energy-Efficient Approximate Signed Multiplier and its extension into a high-performance Convolutional Neural Network (CNN) Accelerator**.

The arithmetic baseline is derived from the hybrid radix-8/16 Booth multiplier proposed by **Guo et al. (IEEE TVLSI 2026)**. This project extends the arithmetic core into a **DSP-free, 182 MHz pipelined Multiply-Accumulate (MAC) unit** and scales it to a **placed-and-routed 32-PE parallel 2D convolution engine** featuring run-time dynamic precision scaling and offline Conv-BatchNorm-ReLU mathematical fusion.

---

## Key Architectural Contributions

1. **Hardware-Efficient Hybrid-Radix Multiplier (FABM):**
   * Implements 1-LUT approximate generation without logic cascading.
   * Adjacent-error compensation canceling opposite-sign errors between adjacent Booth sets.
   * Evaluated across $f=14, 16, 18, 20$ Pareto configurations.

2. **Pipelined Softcore AI MAC Processing Element:**
   * Fully pipelined architecture operating at **182.35 MHz** with **zero dedicated DSP48 slices**.
   * Integrates an overflow-immune **40-bit accumulator with 8 guard bits**.
   * Achieves a **50.0% reduction in core slice logic power** and a **68.9% reduction in Power-Delay Product (PDP)** compared to an exact softcore MAC.

3. **Complete 2D CNN Convolution + ReLU Layer:**
   * Implements a $3 \times 3$ sliding-window receptive field with integrated non-linear ReLU activation.
   * Preserves feature extraction accuracy with **99.19% fidelity (0.813% relative error)** under Q8.8 fixed-point quantization.

4. **Scalable Multi-PE Parallel Array (Placed & Routed):**
   * Scaled from 1 PE to 16 PEs and 32 PEs on a Xilinx Virtex-7 (`xc7vx485tffg1157-1`) FPGA.
   * Full physical implementation (**Place & Route**) proves a **19.42% reduction in routed LUTs (2,546 LUTs saved)** and a **38.10% elimination of high-speed carry-chain primitives (864 CARRY4 blocks / 3,456 carry bits saved)**.

5. **Advanced Optimizations:**
   * **Dynamic Precision Scaling:** Run-time 2-bit control signal (`precision_mode`) dynamically switching between Exact ($f=0$), $f=14$, $f=18$, and $f=20$.
   * **Offline Batch-Norm Folding (`fuse_bn.py`):** Mathematically folds Batch Normalization parameters into fixed-point convolution weights, eliminating hardware dividers.
   * **On-Chip Line-Buffer:** 2-row streaming shift-register window generator for real-time video/sensor streams.

---

## Hardware Implementation & Comparison Results

### Post-Route Implementation (32-PE CNN Array on Xilinx Virtex-7 @ 100 MHz)

| Metric | Exact Softcore Array (32 PEs) | Proposed Approx Array (32 PEs) | Silicon Improvement |
| :--- | :---: | :---: | :---: |
| **Physical Design State** | **Placed & Routed** | **Placed & Routed** | **Physical Silicon** |
| **Dedicated DSP48 Blocks** | **0 (100% Softcore)** | **0 (100% Softcore)** | **100% DSP-Free** |
| **Slice LUTs as Logic** | **13,109 LUTs** | **10,563 LUTs** | **2,546 LUTs Saved (-19.42%)** |
| **CARRY4 Carry Primitives** | **2,268 blocks** | **1,404 blocks** | **864 Blocks Saved (-38.10%)** |
| **High-Speed Carry Bits** | **9,072 bits** | **5,616 bits** | **3,456 Fewer Switching Bits** |
| **Routed Interconnect Nets** | **16,638 wires** | **12,503 wires** | **4,135 Fewer Metal Tracks (-24.85%)** |
| **Total Active Logic Sites** | **20,910 sites** | **17,033 sites** | **3,877 Fewer Active Sites (-18.54%)** |
| **Timing Constraint (100 MHz)** | **Met (Slack: 6.681 ns)** | **Met (Slack: 6.681 ns)** | **Identical High-Speed Closure** |
| **Feature Extraction Fidelity** | 100% (Golden Reference) | **99.19%** | **Only 0.813% Relative Error** |

---

### Isolated MAC Unit Comparison (100 MHz with SAIF Simulation Activity)

| Isolated MAC Metric | Exact Softcore MAC | Proposed Approx MAC ($f=14$) | Quantitative Gain |
| :--- | :---: | :---: | :---: |
| **Dedicated DSPs** | **0** | **0** | **DSP-Free Architecture** |
| **Slice LUTs (Area)** | 306 LUTs | **261 LUTs** | **45 LUTs Saved (-14.71%)** |
| **CARRY4 Primitives** | 53 blocks | **26 blocks** | **27 Blocks Eliminated (-50.94%)** |
| **Slice Registers (FF)** | 75 FFs | 75 FFs | Equal Pipeline Registers |
| **Critical Accumulation Delay**| 3.2 ns | **1.992 ns** | **37.8% Faster Accumulation** |
| **Core Slice Logic Power** | 0.004 W (4 mW) | **0.002 W (2 mW)** | **50.0% Logic Power Reduction** |
| **Power-Delay Product (PDP)** | 12.80 pJ | **3.98 pJ** | **68.9% Energy Reduction / MAC** |

---

## Repository Structure

```text
├── rtl/
│   ├── multiplier/     # Base hybrid-radix multiplier modules
│   ├── mac/            # Exact and Approximate MAC units
│   ├── cnn/            # CNN convolution engine & 16/32-PE arrays
│   └── lib_primitives/ # Standalone reference PPG and PPA modules
├── sim/                # Testbenches & random test vectors
├── constraints/        # Timing constraints (timing.xdc)
├── scripts/            # Python error evaluation & BN fusion
├── docs/               # Schematics and physical silicon floorplans
├── .gitignore
└── README.md

How to Simulate and Synthesize
1. Requirements
EDA Tool: AMD Xilinx Vivado (v2018.2 or newer, verified on v2026.1).
Target Device: Xilinx Virtex-7 xc7vx485tffg1157-1 (or Artix-7/Zynq).
Python Environment: Python 3.8+ with NumPy (for accuracy and BN scripts).
2. Running Simulation in Vivado
Create a new Vivado RTL project and add all files from rtl/ and sim/.
Add constraints/timing.xdc.
Set the desired testbench as top (e.g., tb_dynamic_mac.v or tb_pe_array.v).
Click → Run Simulation → Run Behavioral Simulation.
3. Running Synthesis & Implementation
Set approx_pe_array.v or exact_pe_array.v as Top.
Click Run Synthesis and Run Implementation.
Open Implemented Design and run:

report_utilization
report_timing -delay_type max -max_paths 1
report_power