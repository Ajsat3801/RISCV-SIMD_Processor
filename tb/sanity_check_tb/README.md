# Sanity Check Testbench

Directed testbench used for bring-up and debug, before the UVM environment existed.

* Runs a fixed program containing at least one instance of every supported instruction, then prints the final scalar PRF, vector PRF and DMEM state
* Checking is by inspection - the expected result of each instruction is written alongside it in the program - so this catches gross breakage, not coverage. The UVM testbench does the functional checking

## Files

* `top_tb.sv` - loads the program and preload data, runs the core, prints retirements and the final state
* `test_program.sv` - the instruction image, register and DMEM preloads, with the expected result commented per instruction
* `display_tasks_*.sv` - per-stage tasks that print module inputs and outputs, one file per group of units (`fe`, `ooo`, `rs`, `ex`, `wb`, `prf`, `data`, `core`)