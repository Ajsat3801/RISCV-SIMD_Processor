# Out of Order RISC-V core with integrated SIMD support

**Current Status:** RTL and UVM constrained random testbench complete; extension in progress to incorporate cache and AXI4

## Design

Goal: outperform a scalar core + loosely-coupled vector coprocessor whenever vector work is short, irregular, tightly coupled to scalar control, or dependent on scalar-computed values.

* Scalar and vector share one in-order front end, rename unit and ROB, diverging only at the RS, PRF and EX units
* Out of order execution with register renaming and in-order retirement
* 6 EX units behind 5 reservation stations, each RS feeding at most 2 units
* Instruction queue owns the free-slot list of every RS and binds a slot at dispatch
* RS wakeup by PRF tag match while snooping the CDB
* Round robin writeback arbitration, 1 scalar + 1 vector result to the CDB per cycle
* Branches bypass writeback into the ROB; JAL/LUI/AUIPC resolved in decode, never occupying an EX unit
* No branch predictor: all branches are assumed not taken on fetch and resolved at retirement

![Microarchitecture](https://github.com/Ajsat3801/RISCV-SIMD_Processor/blob/main/doc/block_diagram.drawio.svg)

## Supported Instructions

### RV32I instructions

| Instruction                                          | Processing Unit     |
|------------------------------------------------------|---------------------|
| ADD, SLL, SRL, SUB, AND, OR, XOR, SLT, SLTU          | Scalar ALU          |
| ADDI, SLLI, SRLI, ANDI, ORI, XORI, SLTI, SLTIU       | Scalar ALU          |
| BEQ, BNE, BLT, BGE, BLTU, BGEU                       | Branch Unit         |
| JAL, LUI, AUIPC                                      | Procesed in decoder |
| LW, SW                                               | LSU                 |

### RV32M instructions

| Instruction                                          | Processing Unit     |
|------------------------------------------------------|---------------------|
| MUL, MULH, MULHSU, MULHU                             | Scalar MULDIV       |
| DIV, DIVU, REM, REMU                                 | Scalar MULDIV       |

### RV32V (Vector Extension) instructions

| Instruction                                          | Processing Unit     |
|------------------------------------------------------|---------------------|
| vadd.vv, vsub.vv, vand.vv, vor.vv, vxor.vv           | Vector ALU          | 
| vadd.vx, vsub.vx, vand.vx, vor.vx, vxor.vx, vrsub.vx | Vector ALU          |
| vle32.v, vse32.v                                     | LSU                 |

Note: Fixed configuration: `VLEN = 128`, `SEW = 32`, `LMUL = 1`. No `vsetvli`; vector length is not programmable.

## Configuration

| Parameter | Value | | Parameter | Value |
|---|---|---|---|---|
| Instruction queue | 16 | | ROB | 32 |
| Scalar / vector PRF | 64 each | | Arch regs | 32 + 32 |
| Scalar ALU RS (dual-issue) | 32 | | Other RS (x4) | 8 each |
| Vector length | 4 lanes x 32b | | Store buffer | 4 |
| IMEM | 256 x 32b | | DMEM | 4 banks x 256 x 32b |

Five identical `sky130_sram_1kbyte_1rw_32x256_32` macros: one IMEM, four banked for 128-bit DMEM access.

## Verification

* Directed sanity testbench for bring-up, plus a UVM constrained-random environment scoreboarded against a C++ functional model of the core through DPI
* Regressions run on VCS (UVM-1.2) across randomised seeds; see `tb/top_tb` for the environment

## Directory Structure
```
├── doc                       // Block diagrams, execution path diagrams and result images
├── rtl                       // RTL source. Top level holds top.sv, imem.sv and dmem.sv
│   ├── core                  // The core pipeline, one module per stage/unit
│   ├── if                    // SystemVerilog interfaces for the alloc, data and retirement buses
│   ├── lib                   // Reusable blocks - FIFOs, free queues, multiplier, divider, ALU lane
│   ├── macros                // SRAM macro, instanced 5 times (1 IMEM + 4 DMEM banks)
│   └── pkg                   // Config parameters, packet structs and signal typedefs
└── tb                        // Verification
    ├── sanity_check_tb       // Directed testbench with per-unit display tasks, used for bring-up
    └── top_tb                // UVM constrained random testbench for full chip verification
```
