/*
-----------------------------------
Core module phase 1
-----------------------------------
Consists of full ARR pipeline with one reservation station and 2 ALUs.
Decode is pending

*/

import config_pkg::*;
import signal_pkg::*;

module core #()(
    input clk,
    input reset_n,

    // input of phase 1 is the decoded instructions
    input logic[31:0] instruction,
    input logic[31:0] pc,
    output logic ready
);

decoded_instr_t decoder_to_queue;

decoder u_decoder(
    .clk(clk),
    .reset_n(reset_n),
    .raw_instr(instruction),
    .pc(pc),
    .fetch_valid(instr_valid),
    .decoded_instr(decoder_to_queue)
);

logic[RS_ADDR_W-1:0] rs_slot_released_id_arr[NUMBER_OF_EX-1:0];
logic rs_released_arr[NUMBER_OF_EX-1:0];

queue_to_rob_signal_t queue_to_rob;
queue_to_rat_signal_t queue_to_rat;
queue_to_reg_signal_t queue_to_reg;

logic rob_full;

instruction_queue #() u_instruction_queue(
    .clk(clk),
    .reset_n(reset_n),
    .decoded_instr(decoder_to_queue),
    .queue_ready(ready),
    .rs_slot_released_id(rs_slot_released_id_arr),
    .rs_released(rs_released_arr),
    .alloc_instr_rob(queue_to_rob),
    .alloc_instr_rat(queue_to_rat),
    .alloc_instr_reg(queue_to_reg),
    .rob_full(rob_full)
);

operand_bus_if #() u_operand_bus();
retirement_bus_if #() u_retirement_bus();
common_data_bus_if #() u_common_data_bus();

rob_to_rat_signal_t rob_to_rat;

register_allocation_table #() u_register_allocation_table(
    .clk(clk),
    .reset_n(reset_n),
    .alloc_instr(queue_to_rat),
    .issue_instr(rob_to_rat),
    .retire_instr(u_retirement_bus),
    .issue_data(u_operand_bus)
);

wb_to_rob_branch_signal_t branch_data;

reorder_buffer #() u_reorder_buffer(
    .clk(clk),
    .reset_n(reset_n),
    .input_instr(queue_to_rob),
    .rob_full(rob_full),
    .cdb_data(u_common_data_bus),
    .branch_data(branch_data),
    .issue_instr_rs(u_operand_bus),
    .retire_instr(u_retirement_bus),
    .issue_instr_rat(rob_to_rat)
);

scalar_registers #() u_scalar_registers (
    .clk(clk),
    .reset_n(reset_n),
    .write_data(u_retirement_bus),
    .read_data(queue_to_reg),
    .rs_data_reg(u_operand_bus)
);

rs_to_ex_signal_t dispatch1_op, dispatch2_op;
logic ex1_ready, ex2_ready;

res_station_dual_issue #(
    .CHIP_SELECT(CS_ALU)
) u_alu_rs (
    .clk(clk),
    .reset_n(reset_n),
    .rs_input(u_operand_bus),
    .cdb_data(u_common_data_bus),
    .rs_slot_released_id(rs_slot_released_id_arr[1:0]),
    .rs_slot_released(rs_released_arr[1:0]),
    .ex1_ready(ex1_ready),
    .ex2_ready(ex2_ready),
    .dispatch1_op(dispatch1_op),
    .dispatch2_op(dispatch2_op)
);

ex_to_wb_signal_t ex_result_arr[NUMBER_EX-1:0];
logic wb_ready_arr[NUMBER_EX-1:0];

alu_to_wb_branch_signal_t branch_result_arr[NUMBER_OF_BRANCH_EX-1:0];
logic wb_ready_branch_arr[NUMBER_EX-1:0];

scalar_alu #() alu0 (
    .clk(clk),
    .reset_n(reset_n),
    .dispatched_op(dispatch1_op),
    .ex_ready(ex1_ready),
    .wb_ready(wb_ready_arr[0]),
    .branch_ready(wb_ready_branch_arr[0]),
    .alu_result(ex_result_arr[0]),
    .branch_result(branch_result_arr[0])
);

scalar_alu #() alu1 (
    .clk(clk),
    .reset_n(reset_n),
    .dispatched_op(dispatch2_op),
    .ex_ready(ex2_ready),
    .wb_ready(wb_ready_arr[1]),
    .branch_ready(wb_ready_branch_arr[1]),
    .alu_result(ex_result_arr[1]),
    .branch_result(branch_result_arr[1])
);

writeback_arbiter #()(
    .clk(clk),
    .reset_n(reset_n),
    .ex_result(ex_result_arr),
    .wb_ready(wb_ready_arr),
    .branch_result(branch_result_arr),
    .wb_ready_branch(wb_ready_branch_arr),
    .cdb_data(u_common_data_bus),
    .branch_data(branch_data)
);

endmodule