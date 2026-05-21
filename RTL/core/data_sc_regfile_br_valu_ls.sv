/* ------------------------------------------------------------------------------------------------
 *                            SCALAR PHYSICAL REGISTER FILE - Replica 2
 * ------------------------------------------------------------------------------------------------
 *  Functions/Behavior:
 *  ->  Physical storage for the register values. Architectural registers are mapped to this 
        registers using the RAT.
 *  ->  Replica 1 services branch resolution unit, vector ALU and the loadstore unit.
 *
 *  Inputs:
 *  ->  clock and reset
 *  ->  Read Requests for scalar ALU0, scalar ALU1 and scalar multiply divide
 *  ->  Write request for LUI, AUIPC and JAL instructions from the alloc rename retire unit
 *  ->  Snoop scalar data bus for writeback broadcast
 *
 *  Outputs:
 *  ->  execution requests branch
 *  ->  execution requests for load-store unit
 *      ->  sc_ex_request packet for metadata + operands
 *      ->  data_t packet for store data; used only for stores
 *  ->  execution data for vector_alu
 *      -> 
 * Notes:
 *  ->  Flush doesnt affect the physical register file. The speculative mapping is reset so any 
 *      speculative data can be overwritten 
 *  ->  Write is common for all replicas, so the data remains the same in all 3.
 * ------------------------------------------------------------------------------------------------
 */

module data_sc_regfile_br_valu_ls (
    input logic clk_i,
    input logic reset_ni,

    // inputs from ARR for instructions that dont require an FU
    if_alloc_bus.precalc precalc_i,

    // snooping from CDB
    if_data_bus.prf sc_wb_instr_i,

    // Read operands from RS and send to functional unit
    input  packet_pkg::read_request_t sc_br_rd_req_i,
    output packet_pkg::sc_ex_request_t sc_br_ex_req_o,

    input  signal_pkg::prf_tag_t vc_alu_rd_req_tag_i,
    output signal_pkg::data_t vc_alu_sc_operand_o,

    input  packet_pkg::read_request_t ls_rd_req_i,
    output packet_pkg::sc_ex_request_t ls_ex_req_o,
    output signal_pkg::data_t ls_store_data_o
);

    signal_pkg::data_t regfile[PRF_DEPTH-1:0];
    signal_pkg::data_t operand_a0, operand_a1, operand_vc;
    signal_pkg::data_t operand_b0, operand_b1;

    always_comb begin
        // COMBINATIONAL READS FOR OPERANDS
        operand_a0 = regfile[sc_br_rd_req_i.operand_a_tag.tag];
        operand_b0 = regfile[sc_br_rd_req_i.operand_b_tag.tag];
        operand_a1 = regfile[ls_rd_req_i.operand_a_tag.tag];
        operand_b1 = regfile[ls_rd_req_i.operand_b_tag.tag];
        operand_vc = regfile[vc_alu_rd_req_tag_i.tag];
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

            // READ OPERANDS FOR BRANCH UNIT

            sc_br_ex_req_o.valid     <= sc_br_rd_req_i.valid;
            sc_br_ex_req_o.prf_tag   <= sc_br_rd_req_i.prf_tag;
            sc_br_ex_req_o.rob_id    <= sc_br_rd_req_i.rob_id;
            sc_br_ex_req_o.operation <= sc_br_rd_req_i.operation;

            sc_br_ex_req_o.operand_a <= operand_a0;
            sc_br_ex_req_o.operand_b <= (sc_br_rd_req_i.read_src2) ? 
                operand_b0 : {{20{sc_br_rd_req_i.imm[11]}},sc_br_rd_req_i.imm};

            // READ SCALAR OPERANDS FOR VECTOR ALU
            vc_alu_sc_operand_o <= operand_vc;

            /* READ SCALAR OPERANDS FOR LOAD-STORE UNIT
             *  ->  operand_a is RS1, for both scalar and vector ops
             *  ->  operand_b is imm, used to calculate dest address for scalar ops
             *  ->  ls_store_data is store data used for scalar store word operations only
             */

            ls_ex_req_o.valid     <= ls_rd_req_i.valid;
            ls_ex_req_o.prf_tag   <= ls_rd_req_i.prf_tag;
            ls_ex_req_o.rob_id    <= ls_rd_req_i.rob_id;
            ls_ex_req_o.operation <= ls_rd_req_i.operation;

            ls_ex_req_o.operand_a <= operand_a1;
            ls_ex_req_o.operand_b <= {{20{ls_rd_req_i.imm[11]}},ls_rd_req_i.imm}; 
            
            ls_store_data_o <= operand_b1;
            
        end
    end

endmodule