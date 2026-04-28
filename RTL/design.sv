/*
 * Hacky solution to simulate the core on EDA Playground
 */

`include "config_pkg.sv"
`include "instr_pkg.sv"
`include "signal_pkg.sv"
`include "storage_pkg.sv"

`include "if_alloc_bus.sv"
`include "if_data_bus.sv"
`include "if_vector_request_bus.sv"
`include "if_dispatch_bus.sv"
`include "if_scalar_request_bus.sv"
`include "if_retirement_bus.sv"

`include "lib_circular_fifo_fwft.sv"
`include "lib_rs_slot_freeq_1push.sv"
`include "lib_rs_slot_freeq_2push.sv"
`include "lib_vector_alu_lane.sv"
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

`include "ex_scalar_alu.sv"
`include "ex_branch.sv"
`include "ex_scalar_muldiv.sv"
`include "ex_common_lsu.sv"
`include "ex_vector_alu.sv"

`include "wb_scalar.sv"
`include "wb_vector.sv"

`include "core.sv"