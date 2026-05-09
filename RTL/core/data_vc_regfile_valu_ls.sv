/* 
 * VECTOR PHYSICAL REGISTER FILE
 * Functions:
 *  1)  Physical storage for the register values. Architectural registers
 *      are mapped to this registers using the RAT.
 *  2)  One bit for each register entry indicating whether an instruction
 *      is ready or not.
 * Behavior:
 *  1)  Instruction metadata like chip_select etc are forwarded.
 *  2)  Physical address tags have 1 extra bit. MSB == 0 ? scalar : vector
 *  3)  if instr_i is valid, dest operand tag ready bit reset.
 *  4)  if vc_wb_instr_i is valid, dest data written and dest operand tag 
        ready bit set
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
    output packet_pkg::vc_lsu_ex_request_t vc_lsu_ex_req_o,
);

    signal_pkg::vector_data_t regfile[PRF_DEPTH-1:0];
    signal_pkg::data_t operand_a0, operand_b0, operand_sd;

    always_comb begin
        operand_a0 = regfile[vc_alu_rd_req_i.operand_a_tag.tag];
        operand_b0 = regfile[vc_alu_rd_req_i.operand_b_tag.tag];
        operand_sd = regfile[lsu_store_data_tag];
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
            vc_alu_ex_req_o <= '{  valid, prf_tag, rob_id, operation, 
                                    a_is_vector, b_is_vector,
                                    operand_a0, operand_b0
                                };

            // read LSU operands
            vc_lsu_ex_req_o <= {operand_sd, vc_lsu_rd_req_i.a_is_vector, vc_lsu_rd_req_i.b_is_vector};

        end
    end

endmodule