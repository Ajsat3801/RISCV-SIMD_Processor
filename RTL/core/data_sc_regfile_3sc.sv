/* ------------------------------------------------------------------------------------------------
 *                            SCALAR PHYSICAL REGISTER FILE - Replica 1
 * ------------------------------------------------------------------------------------------------
 *
 *  Functions / Behavior:
 *  ->  Physical register file (PRF) replica that stores scalar register values. Architectural
 *      registers are mapped to physical registers via the Register Alias Table (RAT).
 *  ->  Services 3 scalar functional units in parallel ALU0, ALU1 & Multiply-Divide unit.
 *  ->  On each clock cycle, combinationally reads two operands (A & B) per port from register file
 *      array, then registers the full execution request to the appropriate output port.
 *  ->  Operand B selection is conditional: 
 *      ->  if read_src2 is asserted the register file value is used
 *      ->  otherwise a sign-extended 12-bit immediate is forwarded instead.
 *  ->  Supports two write paths:
 *      ->  pre-calculated values for LUI/AUIPC/JAL instructions forwarded from ARR unit
 *      ->  normal writeback via the scalar data bus snoop.
 *
 *  Inputs:
 *  ->  clk, reset_n
 *  ->  precalc_i — Pre-calculated data interface from the ARR unit for LUI, AUIPC & JAL.
 *  ->  sc_wb_instr_i — Scalar writeback data bus snoop.
 *  ->  sc_rd_req0_i — Read request for Scalar ALU0.
 *  ->  sc_rd_req1_i — Read request for Scalar ALU1.
 *  ->  sc_rd_req2_i — Read request for the Multiply-Divide unit.

 *  Outputs:
 *  ->  sc_ex_req0_o — Registered execution request for Scalar ALU0.
 *  ->  sc_ex_req1_o — Registered execution request for Scalar ALU1.
 *  ->  sc_ex_req2_o — Registered execution request for the Multiply-Divide unit.

 *  Notes:
 *  ->  Flush does not affect the physical register file contents.
 *  ->  Write logic is identical across all PRF replicas ensuring all copies remain coherent.
 *  ->  There is a one-cycle read latency: operands are read combinationally but registered before
 *      being driven to output, so the execution request arrives one cycle after the read request.
 *  ->  Both write ports are independent and can fire in the same cycle. If precalc & sc_wb_instr
 *      are both valid and target the same PRF tag simultaneously, the writeback (sc_wb_instr_i)
 *      write wins because it is the last assignment in the always_ff block.
 *
 * ------------------------------------------------------------------------------------------------
 */

module data_sc_regfile_3sc (
    input logic clk_i,
    input logic reset_ni,

    if_alloc_bus.precalc precalc_i,

    if_data_bus.prf sc_wb_instr_i,

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
        // Combinational reads for operands
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
            // ------------------------------------------------------------------------------------
            //                                          WRITES
            // ------------------------------------------------------------------------------------
            /* 2 scenarios where writing done
             *  ->  there is a pre-calculated value that needs to be stored
             *  ->  instruction is written back
             *  Note: Exact same block as data_sc_regfile_br_valu_ls.sv
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

            // Port 1: Scalar operands for ALU0

            sc_ex_req0_o.valid     <= sc_rd_req0_i.valid;
            sc_ex_req0_o.prf_tag   <= sc_rd_req0_i.prf_tag;
            sc_ex_req0_o.rob_id    <= sc_rd_req0_i.rob_id;
            sc_ex_req0_o.operation <= sc_rd_req0_i.operation;

            sc_ex_req0_o.operand_a <= operand_a0;
            sc_ex_req0_o.operand_b <= (sc_rd_req0_i.read_src2) ? 
                operand_b0 : {{20{sc_rd_req0_i.imm[11]}},sc_rd_req0_i.imm};

            // Port 2: Scalar Operands for ALU1

            sc_ex_req1_o.valid     <= sc_rd_req1_i.valid;
            sc_ex_req1_o.prf_tag   <= sc_rd_req1_i.prf_tag;
            sc_ex_req1_o.rob_id    <= sc_rd_req1_i.rob_id;
            sc_ex_req1_o.operation <= sc_rd_req1_i.operation;

            sc_ex_req1_o.operand_a <= operand_a1;
            sc_ex_req1_o.operand_b <= (sc_rd_req1_i.read_src2) ? 
                operand_b1 : {{20{sc_rd_req1_i.imm[11]}},sc_rd_req1_i.imm};

            // Port 3: Scalar Operands for Multiply-Divide unit

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