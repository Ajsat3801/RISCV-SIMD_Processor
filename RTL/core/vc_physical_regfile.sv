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

module vc_physical_regfile (
    input logic clk_i,
    input logic reset_ni,

    // inputs from ARR
    alloc_bus_if.prf allocated_instr_i,
    dispatch_bus_if.prf allocated_instr_o,

    // snooping from CDB
    data_bus_if.prf writeback_instr_i,

    // inputs from RS for instruction ready to be executed
    input signal_pkg::vc_dispatched_instr_t valu_dispatched_i,
    input signal_pkg::vc_dispatched_instr_t lsu_dispatched_i,
    input logic valu_ready_i,
    input logic lsu_ready_i,

    // sending operands and instruction data to ex
    output signal_pkg::vc_ex_input_signal_t valu_input_o,
    output signal_pkg::vc_ex_input_signal_t lsu_input_o,
    output logic valu_ready_o,
    output logic lsu_ready_i
    
);

    logic[PRF_DEPTH-1:0] ready;
    instr_pkg::vector_data_t regfile[PRF_DEPTH-1:0];

    always_ff @(posedge clk_i) begin
        if (!reset_ni) begin
            for (int i=0; i<PRF_DEPTH; i++) begin
                ready[i] <= 1'b1;
                regfile[i] <= '0;
            end

            valu_input_o <= '0;
            lsu_input_o  <= '0;
            valu_ready_o <= 1'b1;
            lsu_ready_o <= 1'b1;
            
            allocated_instr_o.prf_valid   <= 1'b0;
            allocated_instr_o.chip_select <= instr_pkg::CS_NONE;
            allocated_instr_o.rs_slot <= '0;
            allocated_instr_o.prf_tag <= '0;
            allocated_instr_o.operation.valu <= instr_pkg::VALU_ADD;
            allocated_instr_o.operand_a_tag  <= '0;
            allocated_instr_o.operand_b_tag  <= '0;
            allocated_instr_o.a_is_vector <= 1'b0;
            allocated_instr_o.b_is_vector <= 1'b0;

        end

        else begin

            // writeback
            if (writeback_instr_i.valid && writeback_instr_i.prf_tag.vector) begin
                regfile[writeback_instr_i.prf_tag.tag] <= writeback_instr_i.data;
                ready[writeback_instr_i.prf_tag.tag]   <= 1'b1;
            end

            // allocation
            if (allocated_instr_i.instr.valid) begin
                ready[allocated_instr_i.prf_tag.tag] <= 1'b0;
                allocated_instr_o.operand_a_ready <= ready[allocated_instr_i.operand_a_tag.tag];
                allocated_instr_o.operand_b_ready <= ready[allocated_instr_i.operand_b_tag.tag];
            end
            else begin
                allocated_instr_o.operand_a_ready <= ready[allocated_instr_i.operand_a_tag.tag];
                allocated_instr_o.operand_b_ready <= ready[allocated_instr_i.operand_b_tag.tag];
            end
            
            allocated_instr_o.prf_valid   <= allocated_instr_i.valid;
            allocated_instr_o.chip_select <= allocated_instr_i.instr.chip_select;
            allocated_instr_o.rs_slot   <= allocated_instr_i.rs_slot;
            allocated_instr_o.prf_tag   <= allocated_instr_i.prf_tag;
            allocated_instr_o.operation <= allocated_instr_i.instr.operation;
            allocated_instr_o.operand_a_tag <= allocated_instr_i.operand_a_tag;
            allocated_instr_o.operand_b_tag <= allocated_instr_i.operand_b_tag;
            allocated_instr_o.a_is_vector   <= allocated_instr_i.a_is_vector;
            allocated_instr_o.b_is_vector   <= allocated_instr_i.b_is_vector;

            // read VALU operands
            if (valu_dispatched_i.valid && valu_ready_i) begin
                valu_input_o.valid   <= valu_dispatched_i.valid;
                valu_input_o.prf_tag <= valu_dispatched_i.prf_tag;
                valu_input_o.rob_id  <= valu_dispatched_i.rob_id;
                valu_input_o.operation   <= valu_dispatched_i.operation;
                valu_input_o.a_is_vector <= valu_dispatched_i.a_is_vector;
                valu_input_o.b_is_vector <= valu_dispatched_i.b_is_vector;

                valu_input_o.operand_b <= regfile[valu_dispatched_i.operand_b_tag.tag];

                if (valu_dispatched_i.a_is_vector) begin
                    valu_input_o.operand_a <= regfile[valu_dispatched_i.operand_a_tag.tag];
                end
                else begin
                    valu_input_o.operand_a[0] <= valu_dispatched_i.operand_a;
                    valu_input_o.operand_a[3:1] <= '0;
                end
            end
            else valu_input_o <= '0;

            valu_ready_o <= valu_ready_i;

            // read LSU operands
            if (lsu_dispatched_i.valid) begin
                lsu_input_o.valid   <= lsu_dispatched_i.valid;
                lsu_input_o.prf_tag <= lsu_dispatched_i.prf_tag;
                lsu_input_o.rob_id  <= lsu_dispatched_i.rob_id;
                lsu_input_o.operation   <= lsu_dispatched_i.operation;
                lsu_input_o.a_is_vector <= lsu_dispatched_i.a_is_vector;
                lsu_input_o.b_is_vector <= lsu_dispatched_i.b_is_vector;

                lsu_input_o.operand_b <= regfile[lsu_dispatched_i.operand_b_tag.tag];

                if (lsu_dispatched_i.a_is_vector) begin
                    lsu_input_o.operand_a <= regfile[lsu_dispatched_i.operand_a_tag.tag];
                end
                else begin
                    lsu_input_o.operand_a[0] <= lsu_dispatched_i.operand_a;
                    lsu_input_o.operand_a[3:1] <= '0;
                end

            end
            else lsu_input_o <= '0;

            lsu_ready_o <= lsu_ready_i;

        end
    end

endmodule