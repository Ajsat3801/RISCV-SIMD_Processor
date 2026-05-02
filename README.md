# OoO RISC-V processor with SIMD

**NOTE: Ongoing, not complete**

### Design

Goal to outperform a scalar + vector-coprocessor design whenever vector operations are short, irregular, tightly coupled to scalar control, or dependent on scalar-computed values

* Out of order pipeline with register renaming and in-order retirement
* Multiple Ex units and reservation stations, each RS supports at most 2 ex units
* Instruction queue keeps track of RS slots and assigns to decoded instructions on dispatch
* RS uses tag matching and bus snooping for operand wakeup
* Round Robin writeback arbitration for returning 1 executed instruction to CDB
* Branching bypasses writeback arbitation directly into ROB. Unconditional branches are processed in decoder and written directly in ROB


### Supported Instructions

| Instruction                                          | Processing Unit     |
|------------------------------------------------------|---------------------|
| ADD, SLL, SRL, SUB, AND, OR, XOR, SLT, SLTU          | Scalar ALU          |
| ADDI, SLLI, SRLI, ANDI, ORI, XORI, SLTI, SLTIU       | Scalar ALU          |
| BEQ, BNE, BLT, BGE, BLTU, BGEU                       | Branch Unit         |
| JAL, LUI, AUIPC                                      | Procesed in decoder |
| MUL, DIV                                             | Scalar MULDIV       |
| vadd.vv, vsub.vv, vand.vv, vor.vv, vxor.vv           | Vector ALU          | 
| vadd.vx, vsub.vx, vand.vx, vor.vx, vxor.vx, vrsub.vx | Vector ALU          |
| **PENDING**                                          |                     | 
| LW, SW                                               | LSU                 |
| vle32.v, vse32.v                                     | LSU                 |

### Decoded instruction format

![Alt text](https://github.com/Ajsat3801/RISCV-SIMD_Processor/blob/main/doc/decoding.png 
"Decoded instruction format")

### Microarchitecture

#### Overview

![Alt text](https://github.com/Ajsat3801/RISCV-SIMD_Processor/blob/main/doc/block_diagram.drawio.svg)

#### Stages for each type of instruction

![Alt text](https://github.com/Ajsat3801/RISCV-SIMD_Processor/blob/main/doc/ex_paths/sc_alu_ops.drawio.svg "Flow for scalar ALU and multiply divide operations")  

![Alt text](https://github.com/Ajsat3801/RISCV-SIMD_Processor/blob/main/doc/ex_paths/vc_alu_ops.drawio.svg, "Flow for vector alu operations")

![Alt text](https://github.com/Ajsat3801/RISCV-SIMD_Processor/blob/main/doc/ex_paths/branch_ops.drawio.svg "Flow for conditional branch operations")

![Alt text](https://github.com/Ajsat3801/RISCV-SIMD_Processor/blob/main/doc/ex_paths/ui_ops.drawio.svg, "Flow for unconditional branches and upper immediate operations")

## Verification

* UVM based testbenches
* Unit test benches for each RTL module
* Global test for chip level verification