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
    input logic flush_i,

    if_alloc_bus.precalc precalc_i,

    if_data_bus.prf sc_wb_instr_i,

    input  packet_pkg::read_request_t sc_rd_req0_i,
    output packet_pkg::sc_ex_request_t sc_ex_req0_o,

    input  packet_pkg::read_request_t sc_rd_req1_i,
    output packet_pkg::sc_ex_request_t sc_ex_req1_o,

    input  packet_pkg::read_request_t sc_rd_req2_i,
    output packet_pkg::sc_ex_request_t sc_ex_req2_o
);

//  -----------------------------------------------------------------------------------------------
//          Register flop array

    signal_pkg::data_t regfile[core_config_pkg::PRF_DEPTH-1:0];
    
//  -----------------------------------------------------------------------------------------------
//          Write port 0 (Scalar writeback with mux for precalculated results from ARR)

    logic wrt_wb, wrt_precalc;

    assign wrt_wb = sc_wb_instr_i.valid;
    assign wrt_precalc = precalc_i.precalc_valid;
    
    always_ff @(posedge clk_i) begin

        if(wrt_precalc) regfile[precalc_i.precalc_prf_tag.tag] <= precalc_i.precalc_data;
        if (wrt_wb) regfile[sc_wb_instr_i.prf_tag.tag] <= sc_wb_instr_i.data;

        if(!reset_ni) regfile[0] <= '0;

    end

//  -----------------------------------------------------------------------------------------------
//          Read port 0 (Scalar ALU0 request)  

    signal_pkg::data_t operand_a0, operand_b0;

    always_comb begin
        operand_a0 = regfile[sc_rd_req0_i.operand_a_tag.tag];

        if(sc_rd_req0_i.read_src2) operand_b0 = regfile[sc_rd_req0_i.operand_b_tag.tag];
        else operand_b0 = {{20{sc_rd_req0_i.imm[11]}},sc_rd_req0_i.imm};
    end 

    always_ff @(posedge clk_i) begin
        sc_ex_req0_o <= '{
            valid: sc_rd_req0_i.valid, prf_tag: sc_rd_req0_i.prf_tag,
            rob_id: sc_rd_req0_i.rob_id, operation: sc_rd_req0_i.operation,
            operand_a:operand_a0, operand_b: operand_b0
        };
        if(!reset_ni || flush_i) sc_ex_req0_o.valid <= 1'b0;
    end

//  -----------------------------------------------------------------------------------------------
//          Read port 1 (Scalar ALU1 request)  

    signal_pkg::data_t operand_a1, operand_b1;

    always_comb begin
        operand_a1 = regfile[sc_rd_req1_i.operand_a_tag.tag];

        if(sc_rd_req1_i.read_src2) operand_b1 = regfile[sc_rd_req1_i.operand_b_tag.tag];
        else operand_b1 = {{20{sc_rd_req1_i.imm[11]}},sc_rd_req1_i.imm};
    end 

    always_ff @(posedge clk_i) begin
        sc_ex_req1_o <= '{
            valid: sc_rd_req1_i.valid, prf_tag: sc_rd_req1_i.prf_tag,
            rob_id: sc_rd_req1_i.rob_id, operation: sc_rd_req1_i.operation,
            operand_a:operand_a1, operand_b: operand_b1
        };
        if(!reset_ni || flush_i) sc_ex_req1_o.valid <= 1'b0;
    end

//  -----------------------------------------------------------------------------------------------
//          Read port 2 (Scalar Multiply-Divide unit request)  
    
    signal_pkg::data_t operand_a2, operand_b2;

    always_comb begin
        operand_a2 = regfile[sc_rd_req2_i.operand_a_tag.tag];

        if(sc_rd_req2_i.read_src2) operand_b2 = regfile[sc_rd_req2_i.operand_b_tag.tag];
        else operand_b2 = {{20{sc_rd_req2_i.imm[11]}},sc_rd_req2_i.imm};
    end 

    always_ff @(posedge clk_i) begin
        sc_ex_req2_o <= '{
            valid: sc_rd_req2_i.valid, prf_tag: sc_rd_req2_i.prf_tag,
            rob_id: sc_rd_req2_i.rob_id, operation: sc_rd_req2_i.operation,
            operand_a:operand_a2, operand_b: operand_b2
        };
        if(!reset_ni || flush_i) sc_ex_req2_o.valid <= 1'b0;
    end

endmodule