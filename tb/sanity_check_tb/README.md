# Sanity check TB

* Directed Testbench for checking basic workings of the core
* Contains at least 1 instance of each instruction to ensure that all instructions give the correct output and pipeline is functional.
* Does not ensure complete coverage of all cases. future UVM environment will cover that.

### Working
* top_tb.sv is the main file of the testbench that loads the program and inputs into the core, runs the program and displays the output
* display_tasks_*.sv files contain tasks that print inputs and outputs of each module used for debugging
* test_program.sv contains the test program with the expected output of each instruction and pre-load input of the DMEM.