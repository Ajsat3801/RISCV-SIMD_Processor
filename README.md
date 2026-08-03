# OoO RISC-V processor with SIMD

**NOTE: Ongoing, not complete**
**Current Status:** RTL complete and is passing sanity check testbench. constrained random UVM testbench in progress for in-depth verification.

### Design

Goal to outperform a scalar + vector-coprocessor design whenever vector operations are short, irregular, tightly coupled to scalar control, or dependent on scalar-computed values

* Out of order pipeline with register renaming and in-order retirement
* Multiple Ex units and reservation stations, each RS supports at most 2 ex units
* Instruction queue keeps track of RS slots and assigns to decoded instructions on dispatch
* RS uses tag matching and bus snooping for operand wakeup
* Round Robin writeback arbitration for returning 1 executed instruction to CDB
* Branching bypasses writeback arbitation directly into ROB. Unconditional branches are processed in decoder and written directly in ROB



### Microarchitecture

#### Overview

![Microarchitecture](https://github.com/Ajsat3801/RISCV-SIMD_Processor/blob/main/doc/block_diagram.drawio.svg)

#### Pipeline Execution Paths

<div align="left">
  <img src="https://github.com/Ajsat3801/RISCV-SIMD_Processor/blob/main/doc/ex_paths/sc_alu_ops.drawio.svg" width="90%" alt="Arithmetic and Logic ops flow">
  <p align="center">
    <em>Pipeline Execution Path for Arithmetic & Logic Operations</em>
  </p>
</div>

<div align="left">
  <img src="https://github.com/Ajsat3801/RISCV-SIMD_Processor/blob/main/doc/ex_paths/load_ops.drawio.svg" width="100%" alt="loads flow">
  <p align="center">
    <em>Pipeline Execution Path for Load Operations</em>
  </p>
</div>

<div align="left">
  <img src="https://github.com/Ajsat3801/RISCV-SIMD_Processor/blob/main/doc/ex_paths/store_ops.drawio.svg" width="90%" alt="stores flow">
  <p align="center">
    <em>Pipeline Execution Path for Store Operations</em>
  </p>
</div>

<div align="left">
  <img src="https://github.com/Ajsat3801/RISCV-SIMD_Processor/blob/main/doc/ex_paths/branch_ops.drawio.svg" width="90%" alt="branches flow">
  <p align="center">
    <em>Pipeline Execution Path for Conditional Branch Operations</em>
  </p>
</div>

<div align="left">
  <img src="https://github.com/Ajsat3801/RISCV-SIMD_Processor/blob/main/doc/ex_paths/ui_ops.drawio.svg" width="70%" alt="jumps and ui flow">
  <p align="center">
    <em>Pipeline Execution Path for Unconditional Branch and Upper Immediate Operations</em>
  </p>
</div>


### Supported Instructions

#### RV32I instructions

| Instruction                                          | Processing Unit     |
|------------------------------------------------------|---------------------|
| ADD, SLL, SRL, SUB, AND, OR, XOR, SLT, SLTU          | Scalar ALU          |
| ADDI, SLLI, SRLI, ANDI, ORI, XORI, SLTI, SLTIU       | Scalar ALU          |
| BEQ, BNE, BLT, BGE, BLTU, BGEU                       | Branch Unit         |
| JAL, LUI, AUIPC                                      | Procesed in decoder |
| LW, SW                                               | LSU                 |

#### RV32M instructions

| Instruction                                          | Processing Unit     |
|------------------------------------------------------|---------------------|
| MUL, MULH, MULHSU, MULHU                             | Scalar MULDIV       |
| DIV, DIVU, REM, REMU                                 | Scalar MULDIV       |

#### RV32V (Vector Extension) instructions

| Instruction                                          | Processing Unit     |
|------------------------------------------------------|---------------------|
| vadd.vv, vsub.vv, vand.vv, vor.vv, vxor.vv           | Vector ALU          | 
| vadd.vx, vsub.vx, vand.vx, vor.vx, vxor.vx, vrsub.vx | Vector ALU          |
| vle32.v, vse32.v                                     | LSU                 |

### Decoded instruction format

![Instruction decoding format](https://github.com/Ajsat3801/RISCV-SIMD_Processor/blob/main/doc/decoding.png 
"Decoded instruction format")


## Verification Strategy

* **Stage 1:**Directed testbench for sanity check, to ensure functionality
* **Stage 2:**UVM based global testbench for chip level verification
* **Stage 3:**Unit level constrained random testbenches for each RTL module