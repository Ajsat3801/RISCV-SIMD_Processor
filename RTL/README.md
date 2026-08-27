# Microarchitecture

## Front end (in-order)

* Fetch → decode → instruction queue, all word-addressed; `ECALL` terminates the program
* Decode pre-computes branch/jump targets and LUI/AUIPC immediates so they skip the ALU entirely

* **Decoded instruction format**

![Decoding](https://github.com/Ajsat3801/RISCV-SIMD_Processor/blob/main/doc/decoding.png 
"Decoded instruction format")

## Allocate-Rename-Retire

* Independent scalar and vector rename channels, each with a RAT, a commit table and a free list of PRF tags
* Flush rolls the RAT back to the commit table in one cycle, so no snapshots are kept

## Reorder buffer

* 32-entry circular FIFO, ROB ID = tail pointer, retires one instruction per cycle in program order
* Flushes at retire time rather than at branch resolution, so speculation depth is never tracked

## Reservation stations

| RS | Entries | Feeds |
|---|---|---|
| Scalar ALU (dual-issue) | 32 | ALU0, ALU1 |
| Scalar MUL/DIV | 8 | MUL/DIV |
| Branch | 8 | Branch unit |
| Vector ALU | 8 | Vector ALU |
| Load/Store | 8 | LSU (scalar + vector) |

* Entry issues when both operands are tag-matched ready and the target unit is ready
* Mask-based round robin selection, with a bypass path when the RS is empty and the unit is free

## Register files

* 3 physical register files (PRF) in core, 2 for scalar and 1 for vector. The 2 scalar PRFs are replicas of each other to get read ports without a multi-ported array. Replica A: ALU0/ALU1/MULDIV. Replica B: branch, LSU, scalar operand of `.vx`.
* Combinational read, registered before EX, giving one cycle read latency

## Execution units

* **Scalar ALU x2:** single cycle add/sub, shifts, logicals, SLT
* **MUL/DIV:** multi-cycle radix-4 Booth multiplier and restoring divider behind a READY/MUL/DIV FSM, one op in flight; the 64-bit sub-unit result packs MULH/MUL and REM/DIV in its halves
* **Branch:** combinational compare, result straight to the ROB
* **Vector ALU:** 4 parallel 32-bit lanes, scalar operand replicated for `.vx`
* **LSU:** one unit shared by scalar and vector memory ops

## Memory path

* Stores sit in a 4-entry store buffer until retirement, so memory is never written speculatively
* Loads hitting the buffer are forwarded and bypass DMEM; the rest take the banked SRAM's one-cycle read

## Writeback

* One FWFT FIFO per EX unit decouples execution from CDB arbitration
* Two-step round robin, giving full FIFOs priority so they never stall their unit

## Pipeline Execution Paths

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
