# Testbench for full chip verification

UVM based Constrained-random testbench for full-chip verification, checked against a C++ functional model of the core through DPI.

## Approach

* A randomly generated program is preloaded into IMEM, DMEM and both PRFs, `compute` is asserted, and the run ends when `ECALL` retires or the core goes idle past a threshold
* Checking is end-of-test rather than cycle-by-cycle: the DUT retires out of order internally, so only the committed architectural state is meaningfully comparable against an in-order model

## Environment

| Component | Role |
|---|---|
| `agt_preload` | Active. Drives IMEM/DMEM/PRF preload and the compute strobe |
| `agt_retire` | Passive. Snoops the retirement bus, tracks retire and idle counts |
| `agt_dut_state` | Passive. Samples the final architectural snapshot |
| `agt_alloc` | Passive. Snoops the allocation bus for coverage |
| `scb` | Forwards preloads to the reference model, compares the final snapshot |
| `cov` | Instruction and operand coverage |

* Run state (`complete`, retire count, idle cycles, snapshot taken) lives in a `run_status` object shared through the config DB, with `uvm_event`s handing off between monitors and the test
* `top_tb_if_dut_state` reads committed state hierarchically - PRF contents indexed through the ARR unit's commit tables, DMEM straight out of the four SRAM banks

## Stimulus

* `seq_program_base` owns the flow: build a program image, preload it, assert compute. Derived sequences override `build_program()` only
* Two programs available - a random generator and a directed sanity program covering one instance of each instruction

## Instruction generator

* Programs are deliberately unconstrained apart from what's needed to keep them legal: branch and jump targets must land inside IMEM, loads and stores are based off a reserved register so addresses stay inside DMEM, and `x0`-`x5` are reserved from the destination pool
* `ECALL` is emitted only as the final instruction, as the termination signal
* Preload values are weighted towards corner cases - 0, 1, -1, `INT_MIN`, `INT_MAX` - rather than drawn flat

## Reference model

* In-order C++ model of the core, imported through DPI and given the same preload image as the DUT, then run to completion when the final snapshot arrives
* The scoreboard compares committed scalar registers, vector registers and DMEM, and reports a mismatch count

## Coverage

* `cg_instr` covers the instruction enum sampled at allocation; `cg_operand` bins operand values by class with a scalar `src1 x src2` cross
* Allocation snapshots are buffered by ROB ID and correlated at retirement, so flushed instructions are counted separately from retired ones

## Directory Structure
```
├── agt                       // One folder per agent, each holding its own transactions, common sequencer and driver
│   ├── preload               // Active agent to preload data, monitor, preload/compute items
│   ├── alloc                 // Passive monitor on the allocation bus
│   ├── retire                // Passive monitor on the retirement bus, tracks completion
│   └── dut_state             // Passive monitor sampling the final architectural snapshot
├── env                       // Environment, scoreboard and coverage collector
├── if                        // Interfaces for preload, retirement, allocation and state sampling
├── pkg                       // Config, typedefs, transaction base, instruction encode/decode
├── ref                       // C++ reference model, DPI imports and its SystemVerilog adapter
├── seq                       // Program sequences and the random instruction generator
├── test                      // Base test and the random / directed tests
└── top                       // TB package and top module
```
