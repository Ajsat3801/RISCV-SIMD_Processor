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

module scalar_prf(
    input logic clk_i,
    input logic reset_ni,

    // inputs from scalar RAT
    allocated_instr_if.prf allocated_instr_i,

    // snooping from CDB
    scalar_data_bus_if.snoop writeback_instr_i,

    // sending operands and instruction data to RS
    operand_bus_if.prf instr_o,

    input rob_address_t rob_id
);

    logic[SCALAR_PRF_SIZE-1:0] ready;
    instr_pkg::data_t regfile[SCALAR_PRF_SIZE-1:0];

    logic operand_a_ready_d, operand_b_ready_d;
    instr_pkg::data_t operand_a_d, operand_b_d;

    always_comb begin

        operand_a_d = '0;
        operand_b_d = '0;
        operand_a_ready_d = '0;
        operand_b_ready_d = '0;

        // write into regfile
        if(writeback_instr_i.valid && !writeback_instr_i.prf_tag.vector) begin
            regfile[writeback_instr_i.prf_tag.tag] = writeback_instr_i.data;
            ready[writeback_instr_i.prf_tag.tag] = 1'b1;
        end

        // read reg_files and mark ready as 0 
        if(allocated_instr_i.instr.valid) begin
            ready[allocated_instr_i.prf_tag] = 1'b0;
            
            operand_a_d = regfile[allocated_instr_i.operand_a_tag.tag];
            operand_b_d = regfile[allocated_instr_i.operand_b_tag.tag];

            operand_a_ready_d = ready[allocated_instr_i.operand_a_tag.tag];
            operand_b_ready_d = ready[allocated_instr_i.operand_b_tag.tag];
        end
        
    end

    always_ff @(posedge clk) begin
        if(!reset_ni) begin
            for(i=0;i<SCALAR_PRF_SIZE; i++) begin
                ready[i] <= 1'b0;
                regfile[i] <= '0;
            end
        end
        else begin

            instr_o.prf_input_valid <= allocated_instr_i.valid;
            instr_o.chip_select     <= allocated_instr_i.instr.chip_select;
            instr_o.rs_slot         <= allocated_instr_i.rs_slot;
            instr_o.prf_tag         <= allocated_instr_i.prf_tag;
            instr_o.rob_id          <= rob_id;
            instr_o.operand_a       <= operand_a_d;
            instr_o.operand_b       <= operand_b_d;
            instr_o.operation       <= allocated_instr_i.instr.operation;
            instr_o.sign            <= allocated_instr_i.instr.sign;
            instr_o.operand_a_tag   <= allocated_instr_i.operand_a_tag;
            instr_o.operand_b_tag   <= allocated_instr_i.operand_b_tag;
            instr_o.operand_a_ready <= operand_a_ready_d;
            instr_o.operand_b_ready <= operand_b_ready_d;

        end
    end

endmodule