/* ------------------------------------------------------------------------------------------------
 *                            SCALAR PHYSICAL REGISTER FILE - Replica 2
 * ------------------------------------------------------------------------------------------------
 *
 *  Functions/Behavior
 *  ->  Physical register file (Replica 2) that stores scalar register values.
 *  ->  Services 3 FUs: branch resolution, vector ALU and load-store unit.
 *  ->  Functionally same as replica 1, only ports are different
 *  
 *  Inputs
 *  ->  clk & reset_n
 *  ->  precalc_i — Pre-calculated write port for LUI, AUIPC & JAL.
 *  ->  sc_wb_instr_i — Writeback broadcast bus.
 *  ->  sc_br_rd_req_i — Read request from the branch unit.
 *  ->  vc_alu_rd_req_tag_i — Single PRF tag read request from the vector ALU, used to fetch the
 *      scalar operand for .vx operations.
 *  ->  ls_rd_req_i — Read request from the load-store unit.
 *  
 *  Outputs
 *  ->  sc_br_ex_req_o — Registered execution packet for the branch unit.
 *  ->  vc_alu_sc_operand_o — Registered scalar operand value for the vector ALU, read from the PRF
 *      tag supplied by vc_alu_rd_req_tag_i.
 *  ->  ls_ex_req_o — Registered execution packet for the load-store unit. operand_a is RS1 (base
 *      address); operand_b is the sign-extended 12-bit immediate (address offset for loads/scalar
 *      stores). Metadata is forwarded from ls_rd_req_i.
 *  ->  ls_store_data_o — Store data scalar store word operations.
 *  
 *  Notes
 *  ->  Flush does not affect the physical register file contents.
 *  ->  Write logic is identical across all PRF replicas ensuring all copies remain coherent.
 *  ->  There is a one-cycle read latency: operands are read combinationally but registered before
 *      being driven to output, so the execution request arrives one cycle after the read request.
 *  ->  Both write ports are independent and can fire in the same cycle. If precalc & sc_wb_instr
 *      are both valid and target the same PRF tag simultaneously, the writeback (sc_wb_instr_i)
 *      write wins because it is the last assignment in the always_ff block
 *  ->  Load-store operand_b output is NOT the raw register value, it is the sign-extended immediate
 *      used as address offset. Actual store data is delivered separately on ls_store_data_o.
 *
 * ------------------------------------------------------------------------------------------------ 
 */

module data_sc_regfile_br_valu_ls (
    input logic clk_i,
    input logic reset_ni,

    if_alloc_bus.precalc precalc_i,

    if_data_bus.prf sc_wb_instr_i,

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
        // combinational read for operands
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
            // ------------------------------------------------------------------------------------
            //                                          WRITES
            // ------------------------------------------------------------------------------------
            /*  2 scenarios where writing done
             *  ->  there is a pre-calculated value that needs to be stored
             *  ->  instruction is written back
             *  Note: Exact same block as data_sc_regfile_3sc.sv
             */

            if(precalc_i.precalc_valid) begin
                regfile[precalc_i.precalc_prf_tag] <= precalc_i.precalc_data;
            end

            if (sc_wb_instr_i.valid) begin
                regfile[sc_wb_instr_i.prf_tag.tag] <= sc_wb_instr_i.data;
            end

            // ------------------------------------------------------------------------------------
            //                                          READS
            // ------------------------------------------------------------------------------------

            // Port 0: Scalar operands for branching unit

            sc_br_ex_req_o.valid     <= sc_br_rd_req_i.valid;
            sc_br_ex_req_o.prf_tag   <= sc_br_rd_req_i.prf_tag;
            sc_br_ex_req_o.rob_id    <= sc_br_rd_req_i.rob_id;
            sc_br_ex_req_o.operation <= sc_br_rd_req_i.operation;

            sc_br_ex_req_o.operand_a <= operand_a0;
            sc_br_ex_req_o.operand_b <= operand_b0;
            
            // Port 1: Scalar operands for vector ALU
            vc_alu_sc_operand_o <= operand_vc;

            /* Port 2: Scalar operands for Load-store unit
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