/* ------------------------------------------------------------------------------------------------
 *                                           CORE MODULE
 * ------------------------------------------------------------------------------------------------
 *
 *  Functions/Behavior:
 *  ->  Integrates the whole pipeline
 *  ->  Pre-loading of scalar and vector PRF supported
 *
 *  Inputs:
 *  ->  outputs of fetch module (raw 32bit instruction, current PC and valid)
 *  ->  pre_load variables (flag, address, pre load data)
 *
 *  Outputs
 *  ->  ready for next instruction (input of fetch module)
 *
 *  Notes
 *  ->  Fetch is remaining, current inputs and outputs of core are those of fetch
 *  ->  Index of each FU:   scalar: 0-> alu0, 1->alu1, 2->muldiv, 3->lsu
                            vector: 0-> valu, 1->lsu
 *
 *  Potential Optimizations for physical constraints
 *  ->  separate RS for branching and separate branch packet
 *  ->  smaller RS for branches
 *  ->  send only required info in allocation bus instead of full decoded instruction
 * ------------------------------------------------------------------------------------------------
 */

// import statements for OpenROAD, already included in EDA playground
//import config_pkg::*;

module core #()(
    input  clk_i,
    input  reset_ni,

    input  logic compute_i,

    input  logic sc_preload_valid_i,
    input  signal_pkg::data_t sc_preload_data_i,
    input  signal_pkg::prf_address_t sc_preload_addr_i, 

    input  logic vc_preload_valid_i,
    input  signal_pkg::data_t vc_preload_data_i,
    input  signal_pkg::prf_address_t vc_preload_addr_i, 

    input  signal_pkg::data_t imem_instr_i,
    input  logic imem_valid_i,
    output signal_pkg::pc_t imem_pc_o,
    output logic imem_read_enable_o,

    input  logic [127:0] dmem_data_i,
    output logic [3:0] write_enable_o,
    output logic [7:0] mem_addr_o,
    output logic [127:0] dmem_data_o

);

    logic flush;
    signal_pkg::data_t fetched_instr;
    signal_pkg::pc_t pc;

    packet_pkg::decoded_instr_t decoded_instr, dispatched_instr;
    signal_pkg::rs_slot_id_t dispatched_instr_rs_slot_id;
    
    signal_pkg::rs_slot_id_t released_rs_slot_id_arr [RS_DISPATCH_COUNT-1:0];
    logic rs_slot_released_arr[RS_DISPATCH_COUNT-1:0];

    logic rob_full, arr_full;

    logic queue_ready, fetch_valid;

    // signals from reservation stations to prf 
    packet_pkg::read_request_t sc_rd_req[SCALAR_EX_COUNT-1:0];
    packet_pkg::read_request_t br_rd_req;
    packet_pkg::read_request_t vc_alu_rd_req;
    
    packet_pkg::vc_lsu_read_request_t vc_lsu_rd_req;
    signal_pkg::prf_tag_t vc_alu_rd_req_tag;
    
    // PRF -> EX signals
    packet_pkg::sc_ex_request_t sc_ex_req[SCALAR_EX_COUNT-1:0];
    packet_pkg::sc_ex_request_t br_ex_req;
    packet_pkg::vc_alu_ex_request_t vc_alu_ex_req;
    packet_pkg::vc_lsu_ex_request_t vc_lsu_ex_req;

    signal_pkg::data_t sc_ls_store_data;
    signal_pkg::data_t vc_alu_sc_operand; 
    signal_pkg::vector_data_t vc_ls_store_data;

    // functional units output signals
    // EX -> WB
    
    packet_pkg::sc_ex_result_t sc_ex_result[SCALAR_EX_COUNT-1:0];
    packet_pkg::br_result_t br_ex_result;
    packet_pkg::vc_ex_result_t vc_ex_result[VECTOR_EX_COUNT-1:0];
    packet_pkg::sc_ex_result_t sc_lsu_result;
    packet_pkg::vc_ex_result_t vc_lsu_result;

    packet_pkg::load_store_entry_t lsu_output;
    packet_pkg::store_retire_t store_retire;

    // ready signals from FUs
    // SCALAR: EX -> RS
    // VECTOR: EX -> PRF

    logic sc_ex_ready[SCALAR_EX_COUNT-2:0];
    logic br_ex_ready;
    logic vc_ex_ready[VECTOR_EX_COUNT-2:0];
    logic lsu_ready;

    // ready signals from vector PRF to RS
    logic vc_ex_ready_prf[VECTOR_EX_COUNT-1:0];

    // ready signals from WB
    // WB -> RS
    logic sc_wb_ready[SCALAR_EX_COUNT-1:0];
    logic vc_wb_ready[VECTOR_EX_COUNT-1:0];

    // ready inputs into RS, bitwise and of sc_ex_ready and sc_wb_ready
    logic sc_rs_ex_ready[SCALAR_EX_COUNT-1:0];
    logic vc_rs_ex_ready[VECTOR_EX_COUNT-1:0];

    /*  Naming Convention
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

    if_alloc_bus u_alloc_bus();

    if_data_bus #(.T(signal_pkg::data_t)) u_sc_data_bus();
    if_data_bus #(.T(signal_pkg::vector_data_t)) u_vc_data_bus();
    
    if_retirement_bus u_retirement_bus();

    if_data_bus #(.T(signal_pkg::data_t)) u_sc_prf_input();
    if_data_bus #(.T(signal_pkg::vector_data_t)) u_vc_prf_input();

    genvar i;

    generate
        for(i=0; i<SCALAR_EX_COUNT; i++) begin : gen_sc_ready_gate
            assign  sc_rs_ex_ready[i] = sc_ex_ready[i] && sc_wb_ready[i];
        end

        for(i=0; i<VECTOR_EX_COUNT; i++) begin : gen_vc_ready_gate
            assign vc_rs_ex_ready[i] = vc_ex_ready[i] && vc_wb_ready[i];
        end
    endgenerate

    assign lsu_ready = sc_rs_ex_ready[3] && vc_rs_ex_ready[1];

    always_comb begin
        /*
         * Handling pre-loading of PRF
         */

        if (sc_pre_load_valid_i) begin
            u_sc_prf_input.valid   =  sc_preload_valid_i;
            u_sc_prf_input.prf_tag =  sc_preload_addr_i;
            u_sc_prf_input.data    =  sc_preload_data_i;
        end
        else begin
            u_sc_prf_input.valid   = u_sc_data_bus.valid;
            u_sc_prf_input.prf_tag = u_sc_data_bus.prf_tag;
            u_sc_prf_input.data    = u_sc_data_bus.data;
        end

        if (vc_pre_load_valid_i) begin
            u_vc_prf_input.valid   = vc_preload_valid_i;
            u_vc_prf_input.prf_tag = vc_preload_addr_i;
            u_vc_prf_input.data    = vc_preload_data_i;
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

    fe_fetch u_fetch (
        .clk_i(clk_i),
        .reset_ni(reset_ni),
        .compute_i(compute_i),
        .ready_i(queue_ready),
        .instr_decode_o(fetched_instr),
        .pc_decode_o(pc),
        .fetch_valid_o(fetch_valid),
        .retire_instr_i(u_retirement_bus),
        .instr_imem_i(imem_instr_i),
        .imem_valid_i(imem_valid_i),
        .pc_imem_o(imem_pc_o),
        .read_enable_o(imem_read_enable_o)
    );

    fe_decode u_decode (
        .clk_i(clk_i),
        .reset_ni(reset_ni),
        .fetched_instr_i(fetched_instr),
        .pc_i(pc),
        .fetch_valid_i(fetch_valid),
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
        .arr_full_i(arr_full),
        .dispatched_instr_o(dispatched_instr),
        .rs_slot_id_o(dispatched_instr_rs_slot_id),
        .queue_ready_o(queue_ready)
    );

// ----------------------------------------------------------------------------
//                           OUT OF ORDER COMPONENTS
// ----------------------------------------------------------------------------

    ooo_arr_unit u_alloc_rename_retire (
        .clk_i(clk_i),
        .reset_ni(reset_ni),
        .flush_i(flush),
        .dispatched_instr_i(dispatched_instr),
        .rs_slot_id_i(dispatched_instr_rs_slot_id),
        .retire_instr_i(u_retirement_bus),
        .sc_wb_instr_i(u_sc_data_bus),
        .vc_wb_instr_i(u_vc_data_bus),
        .alloc_instr_o(u_alloc_bus),
        .arr_full_o(arr_full)
    );

    ooo_reorder_buffer u_reorder_buffer (
        .clk_i(clk_i),
        .reset_ni(reset_ni),
        .alloc_instr_io(u_alloc_bus),
        .sc_data_bus_i(u_sc_data_bus),
        .vc_data_bus_i(u_vc_data_bus),
        .branch_result_i(br_ex_result),
        .store_retire_i(store_retire),
        .retire_instr_o(u_retirement_bus),
        .rob_full_o(rob_full),
        .flush_o(flush)
    );

// ----------------------------------------------------------------------------
//                                SCHEDULING
// ----------------------------------------------------------------------------

    rs_scalar_2issue #(.CHIP_SELECT(signal_pkg::CS_SALU)) u_scalar_alu_rs (
        .clk_i(clk_i),
        .reset_ni(reset_ni),
        .flush_i(flush),
        .sc_rs_request_i(u_alloc_bus),
        .sc_data_bus_i(u_sc_data_bus),
        .sc_ex0_ready_i(sc_rs_ex_ready[0]),
        .sc_ex1_ready_i(sc_rs_ex_ready[1]),
        .sc_rd_req0_o(sc_rd_req[0]),
        .sc_rd_req1_o(sc_rd_req[1]),
        .released_rs_slot_id_o(released_rs_slot_id_arr[1:0]),
        .rs_slot_released_o(rs_slot_released_arr[1:0])
    );

    rs_scalar_1issue #(.CHIP_SELECT(signal_pkg::CS_MULDIV)) u_scalar_muldiv_rs (
        .clk_i(clk_i),
        .reset_ni(reset_ni),
        .flush_i(flush),
        .sc_rs_request_i(u_alloc_bus),
        .sc_data_bus_i(u_sc_data_bus),
        .sc_ex_ready_i(sc_rs_ex_ready[2]),
        .sc_rd_req_o(sc_rd_req[2]),
        .released_rs_slot_id_o(released_rs_slot_id_arr[2]),
        .rs_slot_released_o(rs_slot_released_arr[2])
    );

    rs_load_store u_lsu_rs (
        .clk_i(clk_i),
        .reset_ni(reset_ni),
        .flush_i(flush),
        .rs_request_i(u_alloc_bus),
        .sc_data_bus_i(u_sc_data_bus),
        .vc_data_bus_i(u_vc_data_bus),
        .ls_read_request_o(sc_rd_request[3]),
        .vc_lsu_rd_req_o(vc_lsu_rd_req),
        .lsu_ready_i(lsu_ready),
        .released_rs_slot_id_o(released_rs_slot_id_arr[3]),
        .rs_slot_released_o(rs_slot_released_arr[3])
    );

    rs_scalar_1issue #(.CHIP_SELECT(signal_pkg::CS_BRANCH)) u_branch_rs (
        .clk_i(clk_i),
        .reset_ni(reset_ni),
        .flush_i(flush),
        .sc_rs_request_i(u_alloc_bus),
        .sc_data_bus_i(u_sc_data_bus),
        .sc_ex_ready_i(br_ex_ready),
        .sc_rd_req_o(br_rd_req),
        .released_rs_slot_id_o(released_rs_slot_id_arr[4]),
        .rs_slot_released_o(rs_slot_released_arr[4])
    );

    rs_vector_1issue #(.CHIP_SELECT(signal_pkg::CS_VALU)) u_vector_alu_rs (
        .clk_i(clk_i),
        .reset_ni(reset_ni),
        .flush_i(flush),
        .rs_request_i(u_alloc_bus),
        .sc_data_bus_i(u_sc_data_bus),
        .vc_data_bus_i(u_vc_data_bus),
        .vc_ex_ready_i(vc_ex_ready_prf[0]),
        .vc_read_request_o(vc_issued_instr[0]),
        .sc_read_request_tag_o(vc_alu_rd_req_tag),
        .released_rs_slot_id_o(released_rs_slot_id_arr[5]),
        .rs_slot_released_o(rs_slot_released_arr[5])
        
    );

// ----------------------------------------------------------------------------
//                                     DATA
// ----------------------------------------------------------------------------

    data_dmem_controller u_dmem_controller (
        .clk_i(clk_i),
        .reset_ni(reset_ni),
        .dmem_data_i(dmem_data_i),
        .lsu_output(lsu_output),
        .write_enable_o(write_enable_o),
        .mem_addr_o(mem_addr_o),
        .dmem_data_o(dmem_data_o),
        .sc_wb_o(sc_ex_result[3]),
        .vc_wb_o(vc_ex_result[1])
    );
    
    data_sc_regfile_3sc u_scalar_prf_replica0 (
        .clk_i(clk_i),
        .reset_ni(reset_ni),
        .precalc_i(u_alloc_bus),
        .sc_wb_instr_i(u_sc_data_bus),
        .sc_rd_req0_i(sc_rd_req[0]),
        .sc_ex_req0_o(sc_ex_req[0]),
        .sc_rd_req1_i(sc_rd_req[1]),
        .sc_ex_req1_o(sc_ex_req[1]),
        .sc_rd_req2_i(sc_rd_req[2]),
        .sc_ex_req2_o(sc_ex_req[2])
    ); 

    data_sc_regfile_br_valu_ls u_scalar_prf_replica1 (
        .clk_i(clk_i),
        .reset_ni(reset_ni),
        .precalc_i(u_alloc_bus),
        .sc_wb_instr_i(u_sc_data_bus),
        .sc_br_rd_req_i(br_rd_req),
        .sc_br_ex_req_o(br_ex_req),
        .vc_alu_rd_req_tag_i(vc_alu_rd_req_tag),
        .vc_alu_sc_operand_o(vc_alu_sc_operand),
        .ls_rd_req_i(sc_rd_req[3]),
        .ls_ex_req_o(sc_ex_req[3]),
        .ls_store_data_o(sc_ls_store_data)
    );  

    data_vc_regfile_valu_ls u_vector_prf (
        .clk_i(clk_i),
        .reset_ni(reset_ni),
        .vc_wb_instr_i(u_vc_data_bus),
        .vc_alu_rd_req_i(vc_alu_rd_req),
        .vc_alu_ex_req_o(vc_alu_ex_req),
        .vc_lsu_rd_req_i(vc_lsu_rd_req),
        .vc_lsu_ex_req_o(vc_lsu_ex_req)
    ); 

// ----------------------------------------------------------------------------
//                             FUNCTIONAL UNITS
// ----------------------------------------------------------------------------

    ex_scalar_alu u_scalar_alu0 (
        .clk_i(clk_i),
        .reset_ni(reset_ni),
        .flush_i(flush),
        .sc_ex_request_i(sc_ex_req[0]),
        .sc_ex_result_o(sc_ex_result[0]),
        .sc_ex_ready_o(sc_ex_ready[0])
    );

    ex_scalar_alu u_scalar_alu1 (
        .clk_i(clk_i),
        .reset_ni(reset_ni),
        .flush_i(flush),
        .sc_ex_request_i(sc_ex_req[1]),
        .sc_ex_result_o(sc_ex_result[1]),
        .sc_ex_ready_o(sc_ex_ready[1])
    );

    ex_scalar_muldiv u_scalar_muldiv(
        .clk_i(clk_i),
        .reset_ni(reset_ni),
        .flush_i(flush),
        .sc_ex_request_i(sc_ex_req[2]),
        .sc_ex_result_o(sc_ex_result[2]),
        .sc_ex_ready_o(sc_ex_ready[2])
    ); 

    ex_branch u_branch (
        .clk_i(clk_i),
        .reset_ni(reset_ni),
        .flush_i(flush),
        .br_ex_request_i(br_ex_req),
        .br_ex_result_o(br_ex_result),
        .br_ex_ready_o(br_ex_ready)
    );

    ex_load_store u_lsu (
        .clk_i(clk_i),
        .reset_ni(reset_ni),
        .flush_i(flush),
        .lsu_request_i(sc_ex_req[3]),
        .sc_store_data_i(sc_ls_store_data),
        .vc_lsu_ex_request_i(vc_lsu_ex_req),
        .retire_instr_i(u_retirement_bus),
        .lsu_output_o(lsu_output),
        .sc_fwd_load_o(sc_lsu_result),
        .vc_fwd_load_o(vc_lsu_result),
        .store_retire_o(store_retire),
        .sc_ex_ready_o(sc_ex_ready[3]),
        .vc_ex_ready_o(vc_ex_ready[1])
    );

    ex_vector_alu u_vector_alu (
        .clk_i(clk_i),
        .reset_ni(reset_ni),
        .flush_i(flush),
        .vc_ex_request_i(vc_alu_ex_req),
        .sc_operand_i(vc_alu_sc_operand),
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
        .lsu_result_i(sc_lsu_result),
        .wb_ready_o(sc_wb_ready),
        .data_bus_o(u_sc_data_bus)
    );

    wb_vector u_vector_writeback (
        .clk_i(clk_i),
        .reset_ni(reset_ni),
        .flush_i(flush),
        .ex_result_i(vc_ex_result),
        .lsu_result_i(vc_lsu_result),
        .wb_ready_o(vc_wb_ready),
        .data_bus_o(u_vc_data_bus)
    );

endmodule