/* ------------------------------------------------------------------------------------------------
 *                                     VECTOR PHYSICAL REGISTER FILE
 * ------------------------------------------------------------------------------------------------
 *
 *  Functions / Behavior:
 *  ->  Acts as physical register file for vector data.
 *  ->  Snoops Common Data Bus and writes the data to the corresponding PRF tag if vector.
 *  ->  Reads operand A & B for Vector ALU and store data operand for Vector Load/Store ops.
 *
 *  Inputs
 *  ->  clk & reset_n
 *  ->  vc_wb_instr_i — CDB snooping interface for writeback.
 *  ->  vc_alu_rd_req_i — Read request from the Vector ALU reservation station.
 *  ->  vc_lsu_rd_req_i — Read request from the Vector LSU reservation station.
 *
 *  Outputs
 *  ->  vc_alu_ex_req_o — Registered packet sent to the VALU execution unit.
 *  ->  vc_lsu_ex_req_o — Vector data packet sent to the VLSU execution unit.
 *
 *  Notes
 *  ->  No ready output, this module only stores and retrieves data values.
 *  ->  Writeback only occurs when vc_wb_instr_i.prf_tag.vector are true. Scalar writebacks are
 *      silently ignored.
 *  ->  Unique module; No replicas
 *
 * ------------------------------------------------------------------------------------------------
 */

module data_vc_regfile_valu_ls (
    input logic clk_i,
    input logic reset_ni,
    input logic flush_i,

    // snooping from CDB
    if_data_bus.prf vc_wb_instr_i,

    // inputs from RS for instruction ready to be executed
    input packet_pkg::read_request_t vc_alu_rd_req_i,
    input signal_pkg::prf_tag_t vc_lsu_rd_req_i,

    // sending operands and instruction data to ex
    output packet_pkg::vc_alu_ex_request_t vc_alu_ex_req_o,
    output signal_pkg::vector_data_t vc_lsu_ex_req_o
);

    signal_pkg::vector_data_t regfile[core_config_pkg::PRF_DEPTH-1:0];

//  -----------------------------------------------------------------------------------------------
//          Write port 0 (Vector Writeback)

    logic write_en;
    assign write_en = vc_wb_instr_i.valid && vc_wb_instr_i.prf_tag.vector;
    
    always_ff @(posedge clk_i) begin
        if (!reset_ni) regfile[0] <= '0;
        if (write_en)  regfile[vc_wb_instr_i.prf_tag.tag] <= vc_wb_instr_i.data;
    end

//  -----------------------------------------------------------------------------------------------
//          Read port 0 (Vector ALU ex request)
    
    signal_pkg::vector_data_t operand_a0, operand_b0;

    assign operand_a0 = regfile[vc_alu_rd_req_i.operand_a_tag.tag];
    assign operand_b0 = regfile[vc_alu_rd_req_i.operand_b_tag.tag];

    always_ff @(posedge clk_i) begin
        vc_alu_ex_req_o <= '{
            valid: vc_alu_rd_req_i.valid, prf_tag: vc_alu_rd_req_i.prf_tag,
            rob_id: vc_alu_rd_req_i.rob_id, operation: vc_alu_rd_req_i.operation,
            operand_a: operand_a0, operand_b: operand_b0,
            a_is_vector: vc_alu_rd_req_i.a_is_vector, b_is_vector: vc_alu_rd_req_i.b_is_vector
        };
        if(!reset_ni || flush_i) vc_alu_ex_req_o.valid <= 1'b0;
    end

//  -----------------------------------------------------------------------------------------------
//          Read port 1 (Vector operand for LSU)

    signal_pkg::vector_data_t operand_sd;
    assign operand_sd = regfile[vc_lsu_rd_req_i.tag];

    always_ff @(posedge clk_i) begin
        vc_lsu_ex_req_o <= operand_sd;
    end

endmodule