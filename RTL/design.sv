/*
 * Hacky solution to simulate the core on EDA Playground
 */

`include "config_pkg.sv"
`include "instr_pkg.sv"
`include "signal_pkg.sv"
`include "storage_pkg.sv"

`include "alloc_bus_if.sv"
`include "data_bus_if.sv"
`include "dispatch_bus_if.sv"
`include "instruction_bus_if.sv"
`include "operand_bus_if.sv"
`include "retirement_bus_if.sv"

`include "circular_fifo_fwft.sv"
`include "rs_slot_freeq_1push.sv"
`include "rs_slot_freeq_2push.sv"
`include "vc_mini_alu.sv"
`include "sc_multiplier.sv"
`include "sc_divider.sv"

`include "decoder.sv"
`include "instruction_queue.sv"
`include "alloc_rename_retire.sv"
`include "reorder_buffer.sv"

`include "sc_physical_regfile.sv"
`include "vc_physical_regfile.sv"

`include "sc_rs_1issue.sv"
`include "sc_rs_2issue.sv"
`include "vc_rs.sv"
`include "load_store_rs.sv"

`include "sc_alu.sv"
`include "branch_unit.sv"
`include "sc_muldiv.sv"
`include "load_store_unit.sv"
`include "vc_alu.sv"

`include "sc_wb_arbiter.sv"
`include "vc_wb_arbiter.sv"

`include "core.sv"