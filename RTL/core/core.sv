// import statements for OpenROAD, already included in EDA playground
/*
import config_pkg::*;
import signal_pkg::*;
*/

module core #()(
    input clk_i,
    input reset_ni,

    input instr_pkg::data_t raw_instr_i,
    input instr_pkg::data_t pc_i,
    input logic fetch_valid_i,

    input pre_load_i,
    input instr_pkg::prf_tag_t pre_load_addr_i,
    input instr_pkg::data_t pre_load_data_i,

    output logic ready_o
);

/*  CORE FOR PHASE 1
 *  Functions/Behavior
 *   -> Fully scalar OOO unit with 2 scalar ALUs
 *   -> Pre-loading of scalar PRF supported
 *  Inputs
 *   -> outputs of fetch module (raw 32bit instruction, current PC and valid)
 *   -> pre_load variables (flag, address, pre load data)
 *  Outputs
 *   -> ready for next instruction (input of fetch module)
 *  Notes
 *   -> Fetch is remaining, current inputs and outputs of core are those of fetch
 *   -> Vector inputs of OOO modules currently have placeholder values
 */

    logic flush;

    instr_pkg::decoded_instr_t decoded_instr;
    instr_pkg::rs_slot_id_t released_rs_slot_id_arr [RS_DISPATCH_COUNT-1:0];
    logic rs_slot_released_arr[RS_DISPATCH_COUNT-1:0];

    logic rob_full, scalar_arr_full, vector_arr_full;
    
    signal_pkg::sc_ex_input_signal_t sc_alu0_input, sc_alu1_input, br_input, sc_muldiv_input;
    logic sc_alu0_ready, sc_alu1_ready, sc_muldiv_ready;

    signal_pkg::br_output_signal_t branch_result;
    signal_pkg::sc_ex_output_signal_t sc_ex_result[SCALAR_EX_COUNT-1:0];

    logic wb_ready[SCALAR_EX_COUNT-1:0];

    signal_pkg::vc_dispatched_instr_t valu_dispatched_instr, lsu_dispatched_instr;
    logic vc_wb_ready[VECTOR_EX_COUNT-1:0]
    logic valu_ready, lsu_ready;

    signal_pkg::vc_ex_input_signal_t vc_alu_input, vc_lsu_input;
    signal_pkg::vc_ex_output_signal_t vc_ex_result[VECTOR_EX_COUNT-1:0];


// ----------------------------------------------------------------------------
//                              ALL INTERFACES
// ----------------------------------------------------------------------------

    instruction_bus_if                             u_instruction_bus();
    alloc_bus_if                                   u_scalar_alloc_bus();
    alloc_bus_if                                   u_vector_alloc_bus();
    data_bus_if #(.T(instr_pkg::data_t))           u_scalar_data_bus();
    data_bus_if #(.T(instr_pkg::vector_data_t))    u_vector_data_bus();
    operand_bus_if #(.T(instr_pkg::data_t))        u_scalar_operand_bus();
    operand_bus_if #(.T(instr_pkg::vector_data_t)) u_vector_operand_bus();
    retirement_bus_if                              u_retirement_bus();
    data_bus_if #(.T(instr_pkg::data_t))           u_scalar_prf_in();
    dispatch_bus_if u_vector_dispatch_bus();

    always_comb begin
        /*
         * Handling pre-loading of PRF
         */
        if (pre_load_i) begin
            u_scalar_prf_in.valid   = pre_load_i;
            u_scalar_prf_in.prf_tag = pre_load_addr_i;
            u_scalar_prf_in.data    = pre_load_data_i;
        end
        else begin
            u_scalar_prf_in.valid   = u_scalar_data_bus.valid;
            u_scalar_prf_in.prf_tag = u_scalar_data_bus.prf_tag;
            u_scalar_prf_in.data    = u_scalar_data_bus.data;
        end
    end

// ----------------------------------------------------------------------------
//                            IN ORDER FRONT END
// ----------------------------------------------------------------------------

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

// ----------------------------------------------------------------------------
//                           OUT OF ORDER COMPONENTS
// ----------------------------------------------------------------------------

    alloc_rename_retire #(.IS_VECTOR(1'b0)) u_scalar_arr (
        .clk_i(clk_i),
        .reset_ni(reset_ni),
        .flush_i(flush),
        .pre_alloc_instr_i(u_instruction_bus),
        .retire_instr_i(u_retirement_bus),
        .allocated_instr_io(u_scalar_alloc_bus),
        .arr_full_o(scalar_arr_full)
    );

    alloc_rename_retire #(.IS_VECTOR(1'b1)) u_vector_arr (
        .clk_i(clk_i),
        .reset_ni(reset_ni),
        .flush_i(flush),
        .pre_alloc_instr_i(u_instruction_bus),
        .retire_instr_i(u_retirement_bus),
        .allocated_instr_io(u_vector_alloc_bus),
        .arr_full_o(vector_arr_full)
    );

    reorder_buffer u_reorder_buffer (
        .clk_i(clk_i),
        .reset_ni(reset_ni),
        .sc_allocated_instr_io(u_scalar_alloc_bus),
        .vc_allocated_instr_io(u_vector_alloc_bus),
        .scalar_wb_i(u_scalar_data_bus),
        .vector_wb_i(u_vector_data_bus),
        .branch_i(branch_result),
        .alloc_instr_o(u_scalar_operand_bus),
        .retire_instr_o(u_retirement_bus),
        .rob_exp_full_o(rob_full),
        .flush_o(flush)
    );

// ----------------------------------------------------------------------------
//                            PHYSICAL REGISTERS
// ----------------------------------------------------------------------------

    sc_physical_regfile u_scalar_prf (
        .clk_i(clk_i),
        .reset_ni(reset_ni),
        .allocated_instr_i(u_scalar_alloc_bus),
        .writeback_instr_i(u_scalar_prf_in),
        .instr_o(u_scalar_operand_bus)
    );     

    vc_physical_regfile u_vector_prf (
        .clk_i(clk_i),
        .reset_ni(reset_ni),
        .allocated_instr_i(u_vector_alloc_bus),
        .allocated_instr_o(u_vector_dispatch_bus),
        .writeback_instr_i(u_vector_data_bus),
        .valu_dispatched_i(valu_dispatched_instr),
        .lsu_dispatched_i(lsu_dispatched_instr),
        .valu_ready_i(vc_wb_ready[0]),
        .lsu_ready_i(vc_wb_ready[1]),
        .valu_input_o(valu_input),
        .lsu_input_o(lsu_input),
        .valu_ready_o(valu_ready_to_rs),
        .lsu_ready_o(vlsu_ready_to_rs)
    ); 

// ----------------------------------------------------------------------------
//                                SCHEDULING
// ----------------------------------------------------------------------------

    sc_rs_2issue #(.CHIP_SELECT(instr_pkg::CS_SALU)) u_sc_alu_rs (
        .clk_i(clk_i),
        .reset_ni(reset_ni),
        .flush_i(flush),
        .rs_input_i(u_scalar_operand_bus),
        .s_data_bus_i(u_scalar_data_bus),
        .released_rs_slot_id_o(released_rs_slot_id_arr[1:0]),
        .rs_slot_released_o(rs_slot_released_arr[1:0]),
        .wb1_ready_i(wb_ready[0] && sc_alu0_ready),
        .wb2_ready_i(wb_ready[1] && sc_alu1_ready),
        .dispatch1_o(sc_alu0_input),
        .dispatch2_o(sc_alu1_input)
    );

    sc_rs_1issue #(.CHIP_SELECT(instr_pkg::CS_MULDIV)) u_muldiv_rs (
        .clk_i(clk_i),
        .reset_ni(reset_ni),
        .flush_i(flush),
        .dispatched_instr_i(u_scalar_operand_bus),
        .s_data_bus_i(u_scalar_data_bus),
        .released_rs_slot_id_o(released_rs_slot_id_arr[2]),
        .rs_slot_released_o(rs_slot_released_arr[2]),
        .wb_ready_i(wb_ready[2] && sc_muldiv_ready),
        .dispatch_o(sc_muldiv_input)
    );

    load_store_rs u_lsu_rs (
        .clk_i(clk_i),
        .reset_ni(reset_ni),
        .flush_i(flush),
        .sc_operand_bus_i(u_scalar_operand_bus),
        .vc_operand_bus_i(u_vector_operand_bus),
        .sc_data_bus_i(u_scalar_data_bus),
        .vc_data_bus_i(u_vector_data_bus),
        .vc_dispatch_o(lsu_dispatched_instr),
        .sc_dispatch_o(sc_lsu_dispatched_instr),
        .released_rs_slot_id_o(released_rs_slot_id_arr[3]),
        .rs_slot_released_o(rs_slot_released_arr[3]),
        .ex_ready_i(lsu_ready_to_rs)
    );

    sc_rs_1issue #(.CHIP_SELECT(instr_pkg::CS_BRANCH)) u_branch_rs (
        .clk_i(clk_i),
        .reset_ni(reset_ni),
        .flush_i(flush),
        .dispatched_instr_i(u_scalar_operand_bus),
        .s_data_bus_i(u_scalar_data_bus),
        .released_rs_slot_id_o(released_rs_slot_id_arr[4]),
        .rs_slot_released_o(rs_slot_released_arr[4]),
        .wb_ready_i(1'b1),
        .dispatch_o(br_input)
    );

    vc_rs #(.CHIP_SELECT(instr_pkg::CS_VALU)) u_valu_rs (
        .clk_i(clk_i),
        .reset_ni(reset_ni),
        .flush_i(flush),
        .sc_operand_bus_i(u_scalar_operand_bus),
        .vc_dispatch_bus_i(u_vector_dispatch_bus),
        .sc_data_bus_i(u_scalar_data_bus),
        .vc_data_bus_i(u_vector_data_bus),
        .dispatch_o(valu_dispatched_instr),
        .released_rs_slot_id_o(released_rs_slot_id_arr[5]),
        .rs_slot_released_o(rs_slot_released_arr[5]),
        .wb_ready_i(valu_ready_to_rs)
    );

// ----------------------------------------------------------------------------
//                             FUNCTIONAL UNITS
// ----------------------------------------------------------------------------

    sc_alu u_sc_alu0 (
        .clk_i(clk_i),
        .reset_ni(reset_ni),
        .flush_i(flush),
        .alu_input_i(sc_alu0_input),
        .ex_ready_o(sc_alu0_ready),
        .alu_result_o(sc_ex_result[0])
    );

    sc_alu u_sc_alu1 (
        .clk_i(clk_i),
        .reset_ni(reset_ni),
        .flush_i(flush),
        .alu_input_i(sc_alu1_input),
        .ex_ready_o(sc_alu1_ready),
        .alu_result_o(sc_ex_result[1])
    );

    sc_muldiv u_sc_muldiv(
        .clk_i(clk_i),
        .reset_ni(reset_ni),
        .flush_i(flush_i),
        .muldiv_input_i(sc_muldiv_input),
        .ex_ready_o(sc_muldiv_ready),
        .muldiv_result_o(sc_ex_result[2])
    ); 

    branch_unit u_branch_unit (
        .clk_i(clk_i),
        .reset_ni(reset_ni),
        .br_input_i(br_input),
        .br_res_o(branch_result)
    );

    load_store_unit u_lsu (
        .clk_i(),
        .reset_ni(),
        .flush_i(),
        .sc_lsu_dispatched_instr_i(),
        .vc_lsu_dispatched_instr_i(),
        .sc_lsu_result_o(),
        .vc_lsu_result_o(vc_ex_result)
    );

    vc_alu u_vector_alu (
        .clk_i(clk_i),
        .reset_ni(reset_ni),
        .valu_input_i(vc_alu_input),
        .valu_output_o(vc_ex_result[0])
    );

// ----------------------------------------------------------------------------
//                                 WRITEBACK
// ----------------------------------------------------------------------------

    sc_wb_arbiter u_scalar_writeback (
        .clk_i(clk_i),
        .reset_ni(reset_ni),
        .flush_i(flush),
        .sc_ex_result_i(sc_ex_result),
        .wb_ready_o(wb_ready),
        .scalar_data_bus_o(u_scalar_data_bus)
    );

    vc_wb_arbiter u_vector_writeback (
        .clk_i(clk_i),
        .reset_ni(reset_ni),
        .flush_i(flush),
        .ex_result_i(vc_ex_result),
        .wb_ready_o(vc_wb_ready),
        .vector_data_bus_o(u_vector_data_bus)
    );

endmodule