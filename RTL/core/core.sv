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
    input clk_i,
    input reset_ni,

    // input of phase 1 is the decoded instructions
    input instr_pkg::data_t raw_instr_i,
    input instr_pkg::data_t pc_i,
    input logic fetch_valid_i,
    output logic ready_o
);

    logic flush;
    instr_pkg::decoded_instr_t decoded_instr;
    instr_pkg::rs_slot_id_t released_rs_slot_id_arr [NUMBER_OF_EX-1:0];
    logic rs_slot_released_arr[NUMBER_OF_EX-1:0];
    logic rob_full, scalar_arr_full, vector_arr_full;
    signal_pkg::wb_to_rob_branch_signal_t branch_wb;
    instr_pkg::rob_address_t rob_id;
    instr_pkg::rs_to_alu_signal_t alu0_input, alu1_input;
    logic alu0_ready, alu1_ready;
    signal_pkg::alu_to_wb_branch_signal branch_result[NUMBER_OF_BRANCH_EX-1:0];
    signal_pkg::ex_to_wb_signal_t ex_result[NUMBER_OF_EX-1:0];
    logic wb_ready[NUMBER_OF_EX-1:0];
    logic wb_ready_branch[NUMBER_OF_BRANCH_EX-1:0];

    instruction_bus_if u_instruction_bus();
    allocation_bus_if u_scalar_alloc_bus();
    allocation_bus_if u_vector_alloc_bus();
    data_bus_if #(.T(instr_pkg::data_t)) u_scalar_data_bus();
    data_bus_if #(.T(instr_pkg::vector_data_t)) u_vector_data_bus();
    operand_bus_if #(.T(instr_pkg::data_t)) u_scalar_operand_bus();
    operand_bus_if #(.T(instr_pkg::vector_data_t)) u_vector_operand_bus();
    retirement_bus_if u_retirement_bus();

    always_comb begin
        /*
         * Placeholder for vector inputs
         * Currently behaves as a fully scalar unit
         */

        vector_arr_full = 1'b0;
        u_vector_alloc_bus.valid = 1'b0;
        u_vector_data_bus.valid = 1'b0;
        u_vector_operand_bus.valid = 1'b0;

    end

    decoder u_decoder (
        .clk_i(clk_i),
        .reset_ni(reset_ni),
        .raw_instr_i(raw_instr_i),
        .pc_i(pc_i),
        .fetch_valid_i(fetch_valid_i),
        .decoded_instr_o(decoded_instr)
    );

    instruction_queue u_instr_q (
        .clk_i(clk_i),
        .reset_ni(reset_ni),
        .flush_i(flush),
        .decoded_instr_i(decoded_instr),
        .released_rs_slot_id_i(released_rs_slot_id_arr),
        .rs_slot_released_i(rs_slot_released_arr),
        .rob_full_i(rob_full),
        .scalar_arr_full_i(scalar_arr_full),
        .vector_arr_full_i(vector_arr_full),
        .alloc_instr_o(u_instruction_bus),
        .queue_ready_o(ready_o)
    );

    scalar_arr_unit u_scalar_arr(
        .clk_i(clk_i),
        .reset_ni(reset_ni),
        .flush_i(flush),
        .pre_alloc_instr_i(u_instruction_bus),
        .retire_instr_i(u_retirement_bus),
        .sc_allocated_instr_io(u_scalar_alloc_bus),
        .scalar_arr_full_o(scalar_arr_full)
    );

    reorder_buffer u_reorder_buffer(
        .clk_i(clk_i),
        .reset_n_i(reset_ni),
        .sc_allocated_instr_io(u_scalar_alloc_bus),
        .vc_allocated_instr_io(u_vector_alloc_bus),
        .scalar_wb_i(u_scalar_data_bus),
        .vector_wb_i(u_vector_data_bus),
        .branch_i(branch_wb),
        .retire_instr_o(u_retirement_bus),
        .rob_exp_full_o(rob_full),
        .flush_o(flush)
    );

    scalar_prf u_scalar_prf(
        .clk_i(clk_i),
        .reset_ni(reset_ni),
        .allocated_instr_i(scalar_alloc_bus),
        .writeback_instr_i(u_scalar_data_bus),
        .instr_o(u_scalar_operand_bus),
    );

    scalar_rs_2issue #(
        .CHIP_SELECT(CS_ALU)
    ) u_scalar_alu_rs (
        .clk_i(clk_i),
        .reset_ni(reset_ni),
        .flush_i(flush),
        .rs_input_i(u_scalar_operand_bus),
        .s_data_bus_i(u_scalar_data_bus),
        .released_rs_slot_id_o(released_slot_id_arr[1:0]),
        .rs_slot_released_o(rs_slot_released_arr[1:0]),
        .ex1_ready_i(alu0_ready),
        .ex2_ready_i(alu1_ready),
        .dispatch1_o(alu0_input),
        .dispatch2_o(alu1_input)
    );

    scalar_alu u_scalar_alu0 (
        .clk_i(clk_i),
        .reset_ni(reset_ni),
        .flush_i(flush),
        .alu_input_i(alu0_input),
        .ex_ready_o(alu0_ready),
        .wb_ready_i(wb_ready[0]),
        .branch_ready_i(wb_ready_branch[0]),
        .alu_result_o(ex_result[0]),
        .branch_result_o(branch_result[0])
    );

    scalar_alu u_scalar_alu1 (
        .clk_i(clk_i),
        .reset_ni(reset_ni),
        .flush_i(flush),
        .alu_input_i(alu1_input),
        .ex_ready_o(alu1_ready),
        .wb_ready_i(wb_ready[1]),
        .branch_ready_i(wb_ready_branch[1]),
        .alu_result_o(ex_result[1]),
        .branch_result_o(branch_result[1])
    );

    scalar_wb_arbiter u_scalar_writeback (
        .clk_i(clk_i),
        .reset_ni(reset_ni),
        .flush_i(flush_i),
        .ex_result_i(ex_result),
        .wb_ready_o(wb_ready),
        .branch_result_i(branch_result),
        .wb_ready_branch_o(wb_ready_branch),
        .scalar_data_bus_o(u_scalar_data_bus),
        .branch_wb_o(branch_wb)
    );

endmodule