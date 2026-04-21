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
 *  4)  if writeback_instr_i is valid, dest data written and dest operand tag 
        ready bit set
 */

module sc_physical_regfile (
    input logic clk_i,
    input logic reset_ni,

    // inputs from ARR
    alloc_bus_if.prf allocated_instr_i,

    // snooping from CDB
    data_bus_if.prf writeback_instr_i,

    // sending operands and instruction data to RS
    operand_bus_if.prf instr_o
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

            if (writeback_instr_i.valid && !writeback_instr_i.prf_tag.vector) begin
                regfile[writeback_instr_i.prf_tag.tag] <= writeback_instr_i.data;
                ready[writeback_instr_i.prf_tag.tag]   <= 1'b1;
            end

            if (allocated_instr_i.instr.valid) begin
                ready[allocated_instr_i.prf_tag] <= 1'b0;
                
                instr_o.operand_a_ready <= ready[allocated_instr_i.operand_a_tag.tag];
                instr_o.operand_b_ready <= ready[allocated_instr_i.operand_b_tag.tag];

                instr_o.operand_a <= regfile[allocated_instr_i.operand_a_tag.tag];
                instr_o.operand_b <= regfile[allocated_instr_i.operand_b_tag.tag];
            end
            else begin
                instr_o.operand_a_ready <= 1'b0;
                instr_o.operand_b_ready <= 1'b0;

                instr_o.operand_a <= '0;
                instr_o.operand_b <= '0;
            end

            instr_o.prf_valid <= allocated_instr_i.valid;
            instr_o.chip_select   <= allocated_instr_i.instr.chip_select;
            instr_o.rs_slot       <= allocated_instr_i.rs_slot;
            instr_o.prf_tag       <= allocated_instr_i.prf_tag;
            instr_o.operation     <= allocated_instr_i.instr.operation;
            instr_o.operand_a_tag <= allocated_instr_i.operand_a_tag;
            instr_o.operand_b_tag <= allocated_instr_i.operand_b_tag;
            instr_o.a_is_vector   <= allocated_instr_i.a_is_vector;
            instr_o.b_is_vector   <= allocated_instr_i.b_is_vector;

        end
    end

endmodule