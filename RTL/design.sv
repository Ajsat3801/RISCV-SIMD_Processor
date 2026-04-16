/*
 * Hacky solution to simulate the core on EDA Playground
 */

`include "config_pkg.sv"
`include "instr_pkg.sv"
`include "signal_pkg.sv"
`include "storage_pkg.sv"

`include "allocation_bus_if.sv"
`include "data_bus_if.sv"
`include "instruction_bus_if.sv"
`include "operand_bus_if.sv"
`include "retirement_bus_if.sv"

`include "circular_fifo_fwft.sv"
`include "rs_slot_freeq_1push.sv"
`include "rs_slot_freeq_2push.sv"

`include "decoder.sv"
`include "instruction_queue.sv"
`include "alloc_rename_retire.sv"
`include "reorder_buffer.sv"
`include "physical_regfile.sv"
`include "scalar_rs_1issue.sv"
`include "scalar_rs_2issue.sv"
`include "scalar_alu.sv"
`include "branch_unit.sv"
`include "scalar_wb_arbiter.sv"

`include "core.sv"