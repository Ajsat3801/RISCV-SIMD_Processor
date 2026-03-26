# OoO RISC-V processor with SIMD

**NOTE: Ongoing, not complete**

### Design

Goal to outperform a scalar + vector-coprocessor design whenever vector operations are short, irregular, tightly coupled to scalar control, or dependent on scalar-computed values

* Out of order pipeline with register renaming and in-order retirement
* Multiple Ex units and reservation stations, each RS supports at most 2 ex units
* Instruction queue keeps track of RS slots and assigns to decoded instructions on dispatch
* RS uses tag matching and bus snooping for operand wakeup
* Round Robin writeback arbitration for returning 1 executed instruction to CDB
* Branching bypasses writeback arbitation, has a separate arbiter. Unconditional branches are processed in decoder and written directly in ROB


### Supported Instructions

| Instruction                                | Processing Unit     |
|--------------------------------------------|---------------------|
|ADD, SUB, AND, OR, XOR, SLT, SLTU           | Scalar ALU          |
|ADDI, ANDI, ORI, XORI, SLTI, SLTIU          | Scalar ALU          |
|BEQ, BNE, BLT, BGE, BLTU, BGEU              | Scalar ALU          |
| JAL, LUI, AUIPC                            | Procesed in decoder |
| **FUTURE EXPANSION**                       |                     |
| MUL, DIV                                   | Scalar MULDIV       |
| LW, SW                                     | LSU                 |
| vadd.vv, vsub.vv, vand.vv, vor.vv, vxor.vv | Vector ALU          | 
| vadd.vx, vsub.vx, vand.vx, vor.vx, vxor.vx | Vector ALU          | 
| vmul.vx, vdivu.vx                          | Vector LSU          |
| vmul.vv, vdivu.vv                          | Vector LSU          |

## Verification

* UVM based testbenches
* Unit test benches for each RTL module
* Global test for chip level verification