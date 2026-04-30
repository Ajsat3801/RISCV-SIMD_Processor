// import statements for OpenROAD, already included in EDA playground
/*
import config_pkg::*;
import packet_pkg::*;
*/

module core #()(
    input clk_i,
    input reset_ni,

    input instr_pkg::data_t fetched_instr_i,
    input instr_pkg::data_t pc_i,
    input logic fetch_valid_i,

    input sc_pre_load_i,
    input instr_pkg::prf_tag_t sc_pre_load_addr_i,
    input instr_pkg::data_t sc_pre_load_data_i,

    input vc_pre_load_i,
    input instr_pkg::prf_tag_t vc_pre_load_addr_i,
    input instr_pkg::vector_data_t vc_pre_load_data_i,

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
 */

    logic flush;

    packet_pkg::decoded_instr_t decoded_instr;
    
    instr_pkg::rs_slot_id_t released_rs_slot_id_arr [RS_DISPATCH_COUNT-1:0];
    logic rs_slot_released_arr[RS_DISPATCH_COUNT-1:0];

    logic rob_full, sc_arr_full, vc_arr_full;
    
    // functional units input signals
    // for scalar 0-> alu0, 1->alu1, 2->muldiv, 3->lsu
    // for vector 0-> valu, 1->lsu

    // FOR SCALAR : RS -> EX
    // FOR VECTOR : PRF -> EX
    packet_pkg::sc_ex_request_t sc_ex_request[SCALAR_EX_COUNT-1:0];
    packet_pkg::sc_ex_request_t br_ex_request;
    packet_pkg::vc_ex_request_t vc_ex_request[VECTOR_EX_COUNT-1:0];

    // signal from reservation station to prf for vector
    // VECTOR RS -> PRF
    packet_pkg::vc_operand_read_request_t vc_issued_instr[VECTOR_EX_COUNT-1:0];

    // functional units output signals
    // EX -> WB
    packet_pkg::sc_ex_result_t sc_ex_result[SCALAR_EX_COUNT-1:0];
    packet_pkg::br_result_t br_ex_result;
    packet_pkg::vc_ex_result_t vc_ex_result[VECTOR_EX_COUNT-1:0];

    // ready signals from FUs
    // SCALAR: EX -> RS
    // VECTOR: EX -> PRF

    logic sc_ex_ready[SCALAR_EX_COUNT-1:0];
    logic br_ex_ready;
    logic vc_ex_ready[VECTOR_EX_COUNT-1:0];

    // ready signals from vector PRF to RS
    logic vc_ex_ready_prf[VECTOR_EX_COUNT-1:0];

    // ready signals from WB
    // WB -> RS
    logic sc_wb_ready[SCALAR_EX_COUNT-1:0];
    logic vc_wb_ready[VECTOR_EX_COUNT-1:0];

    // ready inputs into RS, bitwise and of sc_ex_ready and sc_wb_ready
    logic sc_rs_ex_ready[SCALAR_EX_COUNT-1:0];
    logic vc_rs_ex_ready[VECTOR_EX_COUNT-1:0];

    /*
        Fetched OP -> fetched_instr
        Decoded OP -> decoded_instr
        Queue OP   -> dispatched_instr
        ARR op     -> alloc_instr
        PRF op to RS -> rs_request
        RS to EX   -> ex_request
        RS to PRF  -> vc_read_request
        PRF to EX  -> ex_request
        ex to wb   -> ex_result
        ROB retire -> retire_instr
    */
    
// ----------------------------------------------------------------------------
//                              ALL INTERFACES
// ----------------------------------------------------------------------------

    if_dispatch_bus u_dispatch_bus();
    
    if_alloc_bus u_sc_alloc_bus();
    if_alloc_bus u_vc_alloc_bus();

    if_scalar_request_bus u_sc_request_bus();
    if_vector_request_bus u_vc_request_bus();

    if_data_bus #(.T(instr_pkg::data_t)) u_sc_data_bus();
    if_data_bus #(.T(instr_pkg::vector_data_t)) u_vc_data_bus();
    
    if_retirement_bus u_retirement_bus();
    
    // used for pre-loading data into the prf 
    if_data_bus #(.T(instr_pkg::data_t)) u_sc_prf_input();
    if_data_bus #(.T(instr_pkg::vector_data_t)) u_vc_prf_input();

    if_data_bus #(.T(instr_pkg::data_t)) u_sc_preload_in();
    if_data_bus #(.T(instr_pkg::vector_data_t)) u_vc_preload_in();

    genvar i;

    generate
        for(i=0; i<SCALAR_EX_COUNT; i++) begin : gen_sc_ready_gate
            assign  sc_rs_ex_ready[i] = sc_ex_ready[i] && sc_wb_ready[i];
        end

        for(i=0; i<VECTOR_EX_COUNT; i++) begin : gen_vc_ready_gate
            assign vc_rs_ex_ready[i] = vc_ex_ready[i] && vc_wb_ready[i];
        end
    endgenerate

    always_comb begin
        /*
         * Handling pre-loading of PRF
         */
        u_sc_preload_in.valid = sc_pre_load_i;
        u_sc_preload_in.prf_tag = sc_pre_load_addr_i;
        u_sc_preload_in.data = sc_pre_load_data_i;

        u_vc_preload_in.valid = vc_pre_load_i;
        u_vc_preload_in.prf_tag = vc_pre_load_addr_i;
        u_vc_preload_in.data = vc_pre_load_data_i;

        if (sc_pre_load_i) begin
            u_sc_prf_input.valid =  u_sc_preload_in.valid;
            u_sc_prf_input.prf_tag =  u_sc_preload_in.prf_tag;
            u_sc_prf_input.data =  u_sc_preload_in.data;
        end
        else begin
            u_sc_prf_input.valid = u_sc_data_bus.valid;
            u_sc_prf_input.prf_tag = u_sc_data_bus.prf_tag;
            u_sc_prf_input.data = u_sc_data_bus.data;
        end

        if (vc_pre_load_i) begin
            u_vc_prf_input.valid = u_vc_preload_in.valid;
            u_vc_prf_input.prf_tag = u_vc_preload_in.prf_tag;
            u_vc_prf_input.data = u_vc_preload_in.data;
        end
        else begin
            u_vc_prf_input.valid = u_vc_data_bus.valid;
            u_vc_prf_input.prf_tag = u_vc_data_bus.prf_tag;
            u_vc_prf_input.data = u_vc_data_bus.data;
        end 

    end

// ----------------------------------------------------------------------------
//                            IN ORDER FRONT END
// ----------------------------------------------------------------------------

    fe_decode u_decode (
        .clk_i(clk_i),
        .reset_ni(reset_ni),
        .fetched_instr_i(fetched_instr_i),
        .pc_i(pc_i),
        .fetch_valid_i(fetch_valid_i),
        .decoded_instr_o(decoded_instr)
    );

    fe_instruction_queue u_instr_q (
        .clk_i(clk_i),
        .reset_ni(reset_ni),
        .flush_i(flush),
        .decoded_instr_i(decoded_instr),
        .released_rs_slot_id_i(released_rs_slot_id_arr),
        .rs_slot_released_i(rs_slot_released_arr),
        .rob_full_i(rob_full),
        .sc_arr_full_i(sc_arr_full),
        .vc_arr_full_i(vc_arr_full),
        .dispatched_instr_o(u_dispatch_bus),
        .queue_ready_o(ready_o)
    );

// ----------------------------------------------------------------------------
//                           OUT OF ORDER COMPONENTS
// ----------------------------------------------------------------------------

    ooo_arr_unit #(.IS_VECTOR(1'b0)) u_scalar_arr (
        .clk_i(clk_i),
        .reset_ni(reset_ni),
        .flush_i(flush),
        .dispatched_instr_i(u_dispatch_bus),
        .retire_instr_i(u_retirement_bus),
        .alloc_instr_o(u_sc_alloc_bus),
        .arr_full_o(sc_arr_full)
    );

    ooo_arr_unit #(.IS_VECTOR(1'b1)) u_vector_arr (
        .clk_i(clk_i),
        .reset_ni(reset_ni),
        .flush_i(flush),
        .dispatched_instr_i(u_dispatch_bus),
        .retire_instr_i(u_retirement_bus),
        .alloc_instr_o(u_vc_alloc_bus),
        .arr_full_o(vc_arr_full)
    );

    ooo_reorder_buffer u_reorder_buffer (
        .clk_i(clk_i),
        .reset_ni(reset_ni),
        .sc_allocated_instr_i(u_sc_alloc_bus),
        .vc_allocated_instr_i(u_vc_alloc_bus),
        .sc_data_bus_i(u_sc_data_bus),
        .vc_data_bus_i(u_vc_data_bus),
        .branch_result_i(br_ex_result),
        .sc_request_o(u_sc_request_bus),
        .vc_request_o(u_vc_request_bus),
        .retire_instr_o(u_retirement_bus),
        .rob_full_o(rob_full),
        .flush_o(flush)
    );

// ----------------------------------------------------------------------------
//                            PHYSICAL REGISTERS
// ----------------------------------------------------------------------------

    phy_regfile_scalar u_scalar_prf (
        .clk_i(clk_i),
        .reset_ni(reset_ni),
        .sc_alloc_instr_i(u_sc_alloc_bus),
        .sc_wb_instr_i(u_sc_prf_input),
        .sc_request_instr_o(u_sc_request_bus)
    );     

    phy_regfile_vector u_vector_prf (
        .clk_i(clk_i),
        .reset_ni(reset_ni),
        .vc_alloc_instr_i(u_vc_alloc_bus),
        .vc_request_instr_o(u_vc_request_bus),
        .vc_wb_instr_i(u_vc_prf_input),
        .vc_issued_instr_i(vc_issued_instr),
        .vc_ex_ready_i(vc_rs_ex_ready),
        .vc_ex_request_o(vc_ex_request),
        .vc_ex_ready_o(vc_ex_ready_prf)
    ); 

// ----------------------------------------------------------------------------
//                                SCHEDULING
// ----------------------------------------------------------------------------

    rs_scalar_2issue #(.CHIP_SELECT(instr_pkg::CS_SALU)) u_scalar_alu_rs (
        .clk_i(clk_i),
        .reset_ni(reset_ni),
        .flush_i(flush),
        .sc_rs_request_i(u_sc_request_bus),
        .sc_data_bus_i(u_sc_data_bus),
        .sc_ex0_ready_i(sc_rs_ex_ready[0]),
        .sc_ex1_ready_i(sc_rs_ex_ready[1]),
        .sc_ex0_request_o(sc_ex_request[0]),
        .sc_ex1_request_o(sc_ex_request[1]),
        .released_rs_slot_id_o(released_rs_slot_id_arr[1:0]),
        .rs_slot_released_o(rs_slot_released_arr[1:0])
    );

    rs_scalar_1issue #(.CHIP_SELECT(instr_pkg::CS_MULDIV)) u_scalar_muldiv_rs (
        .clk_i(clk_i),
        .reset_ni(reset_ni),
        .flush_i(flush),
        .sc_rs_request_i(u_sc_request_bus),
        .sc_data_bus_i(u_sc_data_bus),
        .sc_ex_ready_i(sc_rs_ex_ready[2]),
        .sc_ex_request_o(sc_ex_request[2]),
        .released_rs_slot_id_o(released_rs_slot_id_arr[2]),
        .rs_slot_released_o(rs_slot_released_arr[2])
    );

    rs_common_lsu u_lsu_rs (
        .clk_i(clk_i),
        .reset_ni(reset_ni),
        .flush_i(flush),
        .sc_rs_request_i(u_sc_request_bus),
        .vc_rs_request_i(u_vc_request_bus),
        .sc_data_bus_i(u_sc_data_bus),
        .vc_data_bus_i(u_vc_data_bus),
        .sc_ex_request_o(sc_ex_request[3]),
        .vc_read_request_o(vc_issued_instr[1]),
        .vc_ex_ready_i(vc_ex_ready_prf[1]),
        .released_rs_slot_id_o(released_rs_slot_id_arr[3]),
        .rs_slot_released_o(rs_slot_released_arr[3])
    );

    rs_scalar_1issue #(.CHIP_SELECT(instr_pkg::CS_BRANCH)) u_branch_rs (
        .clk_i(clk_i),
        .reset_ni(reset_ni),
        .flush_i(flush),
        .sc_rs_request_i(u_sc_request_bus),
        .sc_data_bus_i(u_sc_data_bus),
        .sc_ex_ready_i(br_ex_ready),
        .sc_ex_request_o(br_ex_request),
        .released_rs_slot_id_o(released_rs_slot_id_arr[4]),
        .rs_slot_released_o(rs_slot_released_arr[4])
    );

    rs_vector_1issue #(.CHIP_SELECT(instr_pkg::CS_VALU)) u_vector_alu_rs (
        .clk_i(clk_i),
        .reset_ni(reset_ni),
        .flush_i(flush),
        .sc_rs_request_i(u_sc_request_bus),
        .vc_rs_request_i(u_vc_request_bus),
        .sc_data_bus_i(u_sc_data_bus),
        .vc_data_bus_i(u_vc_data_bus),
        .vc_ex_ready_i(vc_ex_ready_prf[0]),
        .vc_read_request_o(vc_issued_instr[0]),
        .released_rs_slot_id_o(released_rs_slot_id_arr[5]),
        .rs_slot_released_o(rs_slot_released_arr[5])
        
    );

// ----------------------------------------------------------------------------
//                             FUNCTIONAL UNITS
// ----------------------------------------------------------------------------

    ex_scalar_alu u_scalar_alu0 (
        .clk_i(clk_i),
        .reset_ni(reset_ni),
        .flush_i(flush),
        .sc_ex_request_i(sc_ex_request[0]),
        .sc_ex_result_o(sc_ex_result[0]),
        .sc_ex_ready_o(sc_ex_ready[0])
    );

    ex_scalar_alu u_scalar_alu1 (
        .clk_i(clk_i),
        .reset_ni(reset_ni),
        .flush_i(flush),
        .sc_ex_request_i(sc_ex_request[1]),
        .sc_ex_result_o(sc_ex_result[1]),
        .sc_ex_ready_o(sc_ex_ready[1])
    );

    ex_scalar_muldiv u_scalar_muldiv(
        .clk_i(clk_i),
        .reset_ni(reset_ni),
        .flush_i(flush),
        .sc_ex_request_i(sc_ex_request[2]),
        .sc_ex_result_o(sc_ex_result[2]),
        .sc_ex_ready_o(sc_ex_ready[2])
    ); 

    ex_branch u_branch (
        .clk_i(clk_i),
        .reset_ni(reset_ni),
        .flush_i(flush),
        .br_ex_request_i(br_ex_request),
        .br_ex_result_o(br_ex_result),
        .br_ex_ready_o(br_ex_ready)
    );

    ex_common_lsu u_lsu (
        .clk_i(clk_i),
        .reset_ni(reset_ni),
        .flush_i(flush),
        .sc_ex_request_i(sc_ex_request[3]),
        .vc_ex_request_i(vc_ex_request[1]),
        .sc_ex_result_o(sc_ex_result[3]),
        .vc_ex_result_o(vc_ex_result[1]),
        .sc_ex_ready_o(sc_ex_ready[3]),
        .vc_ex_ready_o(vc_ex_ready[1])
    );

    ex_vector_alu u_vector_alu (
        .clk_i(clk_i),
        .reset_ni(reset_ni),
        .flush_i(flush),
        .vc_ex_request_i(vc_ex_request[0]),
        .vc_ex_result_o(vc_ex_result[0]),
        .vc_ex_ready_o(vc_ex_ready[0])
    );

// ----------------------------------------------------------------------------
//                                 WRITEBACK
// ----------------------------------------------------------------------------

    wb_scalar u_scalar_writeback (
        .clk_i(clk_i),
        .reset_ni(reset_ni),
        .flush_i(flush),
        .ex_result_i(sc_ex_result),
        .wb_ready_o(sc_wb_ready),
        .data_bus_o(u_sc_data_bus)
    );

    wb_vector u_vector_writeback (
        .clk_i(clk_i),
        .reset_ni(reset_ni),
        .flush_i(flush),
        .ex_result_i(vc_ex_result),
        .wb_ready_o(vc_wb_ready),
        .data_bus_o(u_vc_data_bus)
    );

endmodule