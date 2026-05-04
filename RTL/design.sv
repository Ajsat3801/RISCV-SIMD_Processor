/*
 * Hacky solution to simulate the core on EDA Playground
 */

`include "config_pkg.sv"
`include "signal_pkg.sv"
`include "packet_pkg.sv"

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
`include "lib_scalar_multiplier.sv"
`include "lib_scalar_divider.sv"

`include "fe_decode.sv"
`include "fe_instruction_queue.sv"
`include "ooo_arr_unit.sv"
`include "ooo_reorder_buffer.sv"

`include "phy_regfile_scalar.sv"
`include "phy_regfile_vector.sv"

`include "rs_scalar_1issue.sv"
`include "rs_scalar_2issue.sv"
`include "rs_vector_1issue.sv"
`include "rs_common_lsu.sv"

`include "ex_scalar_alu.sv"
`include "ex_branch.sv"
`include "ex_scalar_muldiv.sv"
`include "ex_common_lsu.sv"
`include "ex_vector_alu.sv"

`include "wb_scalar.sv"
`include "wb_vector.sv"

`include "core.sv"