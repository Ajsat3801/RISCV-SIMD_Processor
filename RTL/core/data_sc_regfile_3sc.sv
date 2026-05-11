/* 
 * SCALAR PHYSICAL REGISTER FILE
 * FOR THE 2 SCALAR ALUS and MULDIV BR units
 * Functions:
 *  1)  Physical storage for the register values. Architectural registers
 *      are mapped to this registers using the RAT.
 *  2)  One bit for each register entry indicating whether an instruction
 *      is ready or not.
 * Behavior:
 *  1)  Instruction metadata like chip_select etc are forwarded.
 *  2)  Physical address tags have 1 extra bit. MSB == 0 ? scalar : vector
 *  3)  if instr_i is valid, dest operand tag ready bit reset.
 *  4)  if sc_wb_instr_i is valid, dest data written and dest operand tag 
        ready bit set
 */

module data_sc_regfile_3sc (
    input logic clk_i,
    input logic reset_ni,

      // inputs from ARR for instructions that dont require an FU
    if_alloc_bus.precalc precalc_i,

    // snooping from CDB
    if_data_bus.prf sc_wb_instr_i,

    // Read operands from RS and send to functional unit
    input  packet_pkg::read_request_t sc_rd_req0_i,
    output packet_pkg::sc_ex_request_t sc_ex_req0_o,

    input  packet_pkg::read_request_t sc_rd_req1_i,
    output packet_pkg::sc_ex_request_t sc_ex_req1_o,

    input  packet_pkg::read_request_t sc_rd_req2_i,
    output packet_pkg::sc_ex_request_t sc_ex_req2_o
);

    signal_pkg::data_t regfile[PRF_DEPTH-1:0];
    signal_pkg::data_t operand_a0, operand_a1, operand_a2;
    signal_pkg::data_t operand_b0, operand_b1, operand_b2;

    always_comb begin
        // COMBINATIONAL READS FOR OPERANDS
        operand_a0 = regfile[sc_rd_req0_i.operand_a_tag.tag];
        operand_b0 = regfile[sc_rd_req0_i.operand_b_tag.tag];
        operand_a1 = regfile[sc_rd_req1_i.operand_a_tag.tag];
        operand_b1 = regfile[sc_rd_req1_i.operand_b_tag.tag]; 
        operand_a2 = regfile[sc_rd_req2_i.operand_a_tag.tag];
        operand_b2 = regfile[sc_rd_req2_i.operand_b_tag.tag]; 
    end

    always_ff @(posedge clk_i) begin
        if (!reset_ni) begin
            for (int i=0; i<PRF_DEPTH; i++) begin
                regfile[i] <= '0;
            end
        end

        else begin
            /* WRITING TO THE PRF
             * 2 scenarios where its done
             *  ->  there is a pre-calculated value that needs to be stored
             *  ->  instruction is written back
             */

            if(precalc_i.precalc_valid) begin
                regfile[precalc_i.precalc_prf_tag] <= precalc_i.precalc_data;
            end

            if (sc_wb_instr_i.valid) begin
                regfile[sc_wb_instr_i.prf_tag.tag] <= sc_wb_instr_i.data;
            end

            // READ SCALAR OPERANDS FOR ALU0

            sc_ex_req0_o.valid     <= sc_rd_req0_i.valid;
            sc_ex_req0_o.prf_tag   <= sc_rd_req0_i.prf_tag;
            sc_ex_req0_o.rob_id    <= sc_rd_req0_i.rob_id;
            sc_ex_req0_o.operation <= sc_rd_req0_i.operation;

            sc_ex_req0_o.operand_a <= operand_a0;
            sc_ex_req0_o.operand_b <= (sc_rd_req0_i.read_src2) ? 
                operand_b0 : {{20{sc_rd_req0_i.imm[11]}},sc_rd_req0_i.imm};

            // READ SCALAR OPERANDS FOR ALU1

            sc_ex_req1_o.valid     <= sc_rd_req1_i.valid;
            sc_ex_req1_o.prf_tag   <= sc_rd_req1_i.prf_tag;
            sc_ex_req1_o.rob_id    <= sc_rd_req1_i.rob_id;
            sc_ex_req1_o.operation <= sc_rd_req1_i.operation;

            sc_ex_req1_o.operand_a <= operand_a1;
            sc_ex_req1_o.operand_b <= (sc_rd_req1_i.read_src2) ? 
                operand_b1 : {{20{sc_rd_req1_i.imm[11]}},sc_rd_req1_i.imm};

            // READ SCALAR OPERANDS FOR MULDIV

            sc_ex_req2_o.valid     <= sc_rd_req2_i.valid;
            sc_ex_req2_o.prf_tag   <= sc_rd_req2_i.prf_tag;
            sc_ex_req2_o.rob_id    <= sc_rd_req2_i.rob_id;
            sc_ex_req2_o.operation <= sc_rd_req2_i.operation;

            sc_ex_req2_o.operand_a <= operand_a2;
            sc_ex_req2_o.operand_b <= (sc_rd_req2_i.read_src2) ? 
                operand_b2 : {{20{sc_rd_req2_i.imm[11]}},sc_rd_req2_i.imm};
            
        end
    end

endmodule