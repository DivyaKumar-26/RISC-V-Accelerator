# Design and Verification of a Reconfigurable MAC-Based Accelerator for FFT and Matrix Multiplication Workloads on RISC-V

## Overview

This project focuses on the design, implementation, and verification of a custom hardware accelerator attached to a RISC-V processor. The accelerator is built around a reusable Multiply-Accumulate (MAC) architecture and is designed to accelerate both Digital Signal Processing (DSP) and Edge AI workloads.

The architecture supports:

* Matrix Multiplication Acceleration
* FFT Butterfly Operations
* Complex Multiplication
* SIMD-Based Parallel Processing (Planned Extension)
* Integration with a Single-Cycle RISC-V Processor

The primary goal is to demonstrate how a common MAC-centric hardware architecture can be reused across multiple computational domains while minimizing hardware overhead.

---

## Project Objectives

* Design a reusable MAC processing engine.
* Accelerate matrix multiplication operations used in AI inference workloads.
* Accelerate FFT butterfly computations used in DSP applications.
* Integrate the accelerator with a RISC-V processor.
* Evaluate performance improvements compared to software execution.
* Explore SIMD extensions for increased throughput.

---

## System Architecture

```text
                    RISC-V Processor
                           |
                           |
                 Accelerator Interface
                           |
       ---------------------------------------
       |                                     |
       |        Reconfigurable Accelerator    |
       |                                     |
       ---------------------------------------
             |            |           |
             |            |           |
            MAC     Complex Mult      FFT
             |            |           |
             --------------------------------
                           |
                        SIMD
                      (Future)
```

---

## Accelerator Modes

### 1. MAC Mode

Performs:

ACC = ACC + A × B

Applications:

* Matrix Multiplication
* FIR Filters
* Convolution
* Neural Network Computation

---

### 2. Complex Multiplication Mode

Performs:

(a + jb)(c + jd)

Applications:

* FFT
* DSP Algorithms
* Communication Systems

---

### 3. FFT Butterfly Mode

Performs:

X = A + WB

Y = A - WB

Applications:

* FFT
* Spectral Analysis
* Signal Processing

---



## Development Roadmap

### Phase 1

* Single-Cycle RISC-V Processor
* Basic Verification

### Phase 2

* MAC Unit Design
* MAC Verification

### Phase 3

* Complex Multiplier Design
* FFT Butterfly Unit

### Phase 4

* Matrix Multiplication Accelerator

### Phase 5

* Accelerator Controller

### Phase 6

* RISC-V Integration

### Phase 7

* Performance Benchmarking

### Phase 8

* SIMD Extension (Future Work)

---

## Tools Used

* Verilog
* AMD Vivado
* Vivado Simulator (xsim)
* Git
* GitHub

---

## Evaluation Metrics

The accelerator will be evaluated using:

* Cycle Count
* Latency
* Throughput
* LUT Utilization
* Flip-Flop Usage
* DSP Utilization
* Maximum Operating Frequency
* Estimated Power Consumption

---

## Expected Applications

### DSP Workloads

* FFT
* FIR Filtering
* Spectral Analysis
* Signal Processing

### Edge AI Workloads

* Matrix Multiplication
* Neural Network Inference
* Convolution Operations

---

## Future Work

* SIMD Extension
* Multi-PE Accelerator Architecture
* Custom RISC-V ISA Extensions
* Hardware Deployment on FPGA
* Quantized Neural Network Acceleration

---

## Author

Divya Kumar

Project Area:
Computer Architecture | Digital Design | Hardware Accelerators | RISC-V | DSP | Edge AI
