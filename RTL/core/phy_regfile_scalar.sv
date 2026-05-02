/* 
 * SCALAR PHYSICAL REGISTER FILE
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

module phy_regfile_scalar (
    input logic clk_i,
    input logic reset_ni,

    // inputs from ARR
    if_alloc_bus.prf sc_alloc_instr_i,

    // snooping from CDB
    if_data_bus.prf sc_wb_instr_i,

    // sending operands and instruction data to RS
    if_scalar_request_bus.prf sc_request_instr_o
);

    logic[PRF_DEPTH-1:0] ready;
    instr_pkg::data_t regfile[PRF_DEPTH-1:0];

    always_ff @(posedge clk_i) begin
        if (!reset_ni) begin
            for (int i=0; i<PRF_DEPTH; i++) begin
                ready[i] <= 1'b1;
                regfile[i] <= '0;
            end
        end

        else begin

            if (sc_wb_instr_i.valid && !sc_wb_instr_i.prf_tag.vector) begin
                regfile[sc_wb_instr_i.prf_tag.tag] <= sc_wb_instr_i.data;
                ready[sc_wb_instr_i.prf_tag.tag]   <= 1'b1;
            end

            if (sc_alloc_instr_i.instr.valid) begin
                ready[sc_alloc_instr_i.prf_tag] <= 1'b0;
                
                sc_request_instr_o.operand_a_ready <= ready[sc_alloc_instr_i.operand_a_tag.tag];
                sc_request_instr_o.operand_b_ready <= ready[sc_alloc_instr_i.operand_b_tag.tag];

                sc_request_instr_o.operand_a <= regfile[sc_alloc_instr_i.operand_a_tag.tag];
                sc_request_instr_o.operand_b <= regfile[sc_alloc_instr_i.operand_b_tag.tag];

                if(sc_alloc_instr_i.instr.pre_calc && sc_alloc_instr_i.write_to_reg) begin
                    regfile[sc_alloc_instr_i.prf_tag.tag] <= {  sc_alloc_instr_i.instr.src1_address,
                                                                sc_alloc_instr_i.instr.src2_address,
                                                                sc_alloc_instr_i.instr.imm, 
                                                                sc_alloc_instr_i.instr.extend
                                                            };
                    ready[sc_alloc_instr_i.prf_tag.tag] <= 1'b1;
                end
            end
            else begin
                sc_request_instr_o.operand_a_ready <= 1'b0;
                sc_request_instr_o.operand_b_ready <= 1'b0;

                sc_request_instr_o.operand_a <= '0;
                sc_request_instr_o.operand_b <= '0;
            end

            sc_request_instr_o.prf_valid     <= sc_alloc_instr_i.valid && !(sc_alloc_instr_i.instr.chip_select == instr_pkg::NONE);
            sc_request_instr_o.chip_select   <= sc_alloc_instr_i.instr.chip_select;
            sc_request_instr_o.rs_slot       <= sc_alloc_instr_i.rs_slot;
            sc_request_instr_o.prf_tag       <= sc_alloc_instr_i.prf_tag;
            sc_request_instr_o.operation     <= sc_alloc_instr_i.instr.operation;
            sc_request_instr_o.operand_a_tag <= sc_alloc_instr_i.operand_a_tag;
            sc_request_instr_o.operand_b_tag <= sc_alloc_instr_i.operand_b_tag;
            sc_request_instr_o.a_is_vector   <= sc_alloc_instr_i.a_is_vector;
            sc_request_instr_o.b_is_vector   <= sc_alloc_instr_i.b_is_vector;

        end
    end

endmodule