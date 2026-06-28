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
 *  ->  vc_lsu_ex_req_o — Registered packet sent to the VLSU execution unit.
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

    // snooping from CDB
    if_data_bus.prf vc_wb_instr_i,

    // inputs from RS for instruction ready to be executed
    input packet_pkg::read_request_t vc_alu_rd_req_i,
    input packet_pkg::vc_lsu_read_request_t vc_lsu_rd_req_i,

    // sending operands and instruction data to ex
    output packet_pkg::vc_alu_ex_request_t vc_alu_ex_req_o,
    output packet_pkg::vc_lsu_ex_request_t vc_lsu_ex_req_o
);

    signal_pkg::vector_data_t regfile[PRF_DEPTH-1:0];
    signal_pkg::vector_data_t operand_a0, operand_b0, operand_sd;

    always_comb begin
        operand_a0 = regfile[vc_alu_rd_req_i.operand_a_tag.tag];
        operand_b0 = regfile[vc_alu_rd_req_i.operand_b_tag.tag];
        operand_sd = regfile[vc_lsu_rd_req_i.store_data_tag.tag];
    end

    always_ff @(posedge clk_i) begin
        if (!reset_ni) begin
            for (int i=0; i<PRF_DEPTH; i++) regfile[i] <= '0;
        end

        else begin

            // writeback
            if (vc_wb_instr_i.valid && vc_wb_instr_i.prf_tag.vector) begin
                regfile[vc_wb_instr_i.prf_tag.tag] <= vc_wb_instr_i.data;
            end

            // read VALU operands
            vc_alu_ex_req_o <= '{   vc_alu_rd_req_i.valid, vc_alu_rd_req_i.prf_tag, vc_alu_rd_req_i.rob_id, 
                                    vc_alu_rd_req_i.operation, operand_a0, operand_b0,
                                    vc_alu_rd_req_i.a_is_vector, vc_alu_rd_req_i.b_is_vector
                                };

            // read LSU operands
            vc_lsu_ex_req_o <= {operand_sd, vc_lsu_rd_req_i.a_is_vector, vc_lsu_rd_req_i.b_is_vector};

        end
    end

endmodule