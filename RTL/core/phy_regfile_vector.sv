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
 *  4)  if vc_wb_instr_i is valid, dest data written and dest operand tag 
        ready bit set
 */

module phy_regfile_vector (
    input logic clk_i,
    input logic reset_ni,

    // inputs from ARR
    if_alloc_bus.prf vc_alloc_instr_i,
    if_vector_request_bus.prf vc_request_instr_o,

    // snooping from CDB
    if_data_bus.prf vc_wb_instr_i,

    // inputs from RS for instruction ready to be executed
    input packet_pkg::vc_operand_read_request_t vc_issued_instr_i[VECTOR_EX_COUNT-1:0],
    input logic vc_ex_ready_i[VECTOR_EX_COUNT-1:0],

    // sending operands and instruction data to ex
    output packet_pkg::vc_ex_request_t vc_ex_request_o[VECTOR_EX_COUNT-1:0],
    output logic vc_ex_ready_o[VECTOR_EX_COUNT-1:0]
    
);

    logic[PRF_DEPTH-1:0] ready;
    instr_pkg::vector_data_t regfile[PRF_DEPTH-1:0];

    always_ff @(posedge clk_i) begin
        if (!reset_ni) begin
            for (int i=0; i<PRF_DEPTH; i++) begin
                ready[i] <= 1'b1;
                regfile[i] <= '0;
            end

            vc_ex_request_o[0] <= '0;
            vc_ex_request_o[1]  <= '0;
            vc_ex_ready_o[0] <= 1'b1;
            vc_ex_ready_o[1] <= 1'b1;
            
            vc_request_instr_o.valid   <= 1'b0;
            vc_request_instr_o.chip_select <= instr_pkg::NONE;
            vc_request_instr_o.rs_slot <= '0;
            vc_request_instr_o.prf_tag <= '0;
            vc_request_instr_o.operation.valu <= instr_pkg::VALU_ADD;
            vc_request_instr_o.operand_a_tag  <= '0;
            vc_request_instr_o.operand_b_tag  <= '0;
            vc_request_instr_o.a_is_vector <= 1'b0;
            vc_request_instr_o.b_is_vector <= 1'b0;

        end

        else begin

            // writeback
            if (vc_wb_instr_i.valid && vc_wb_instr_i.prf_tag.vector) begin
                regfile[vc_wb_instr_i.prf_tag.tag] <= vc_wb_instr_i.data;
                ready[vc_wb_instr_i.prf_tag.tag]   <= 1'b1;
            end

            // allocation
            if (vc_alloc_instr_i.instr.valid) begin
                ready[vc_alloc_instr_i.prf_tag.tag] <= 1'b0;
                vc_request_instr_o.operand_a_ready <= ready[vc_alloc_instr_i.operand_a_tag.tag];
                vc_request_instr_o.operand_b_ready <= ready[vc_alloc_instr_i.operand_b_tag.tag];
            end
            else begin
                vc_request_instr_o.operand_a_ready <= ready[vc_alloc_instr_i.operand_a_tag.tag];
                vc_request_instr_o.operand_b_ready <= ready[vc_alloc_instr_i.operand_b_tag.tag];
            end
            
            vc_request_instr_o.valid   <= vc_alloc_instr_i.valid;
            vc_request_instr_o.chip_select <= vc_alloc_instr_i.instr.chip_select;
            vc_request_instr_o.rs_slot   <= vc_alloc_instr_i.rs_slot;
            vc_request_instr_o.prf_tag   <= vc_alloc_instr_i.prf_tag;
            vc_request_instr_o.operation <= vc_alloc_instr_i.instr.operation;
            vc_request_instr_o.operand_a_tag <= vc_alloc_instr_i.operand_a_tag;
            vc_request_instr_o.operand_b_tag <= vc_alloc_instr_i.operand_b_tag;
            vc_request_instr_o.a_is_vector   <= vc_alloc_instr_i.a_is_vector;
            vc_request_instr_o.b_is_vector   <= vc_alloc_instr_i.b_is_vector;

            // read VALU operands
            if (vc_issued_instr_i[0].valid && vc_ex_ready_i[0]) begin
                vc_ex_request_o[0].valid   <= vc_issued_instr_i[0].valid;
                vc_ex_request_o[0].prf_tag <= vc_issued_instr_i[0].prf_tag;
                vc_ex_request_o[0].rob_id  <= vc_issued_instr_i[0].rob_id;
                vc_ex_request_o[0].operation   <= vc_issued_instr_i[0].operation;
                vc_ex_request_o[0].a_is_vector <= vc_issued_instr_i[0].a_is_vector;
                vc_ex_request_o[0].b_is_vector <= vc_issued_instr_i[0].b_is_vector;

                vc_ex_request_o[0].operand_b <= regfile[vc_issued_instr_i[0].operand_b_tag.tag];

                if (vc_issued_instr_i[0].a_is_vector) begin
                    vc_ex_request_o[0].operand_a <= regfile[vc_issued_instr_i[0].operand_a_tag.tag];
                end
                else begin
                    vc_ex_request_o[0].operand_a[0] <= vc_issued_instr_i[0].operand_a;
                    vc_ex_request_o[0].operand_a[3:1] <= '0;
                end
            end
            else vc_ex_request_o[0] <= '0;

            vc_ex_ready_o[0] <= vc_ex_ready_i[0];

            // read LSU operands
            if (vc_issued_instr_i[1].valid) begin
                vc_ex_request_o[1].valid   <= vc_issued_instr_i[1].valid;
                vc_ex_request_o[1].prf_tag <= vc_issued_instr_i[1].prf_tag;
                vc_ex_request_o[1].rob_id  <= vc_issued_instr_i[1].rob_id;
                vc_ex_request_o[1].operation   <= vc_issued_instr_i[1].operation;
                vc_ex_request_o[1].a_is_vector <= vc_issued_instr_i[1].a_is_vector;
                vc_ex_request_o[1].b_is_vector <= vc_issued_instr_i[1].b_is_vector;

                vc_ex_request_o[1].operand_b <= regfile[vc_issued_instr_i[1].operand_b_tag.tag];

                if (vc_issued_instr_i[1].a_is_vector) begin
                    vc_ex_request_o[1].operand_a <= regfile[vc_issued_instr_i[1].operand_a_tag.tag];
                end
                else begin
                    vc_ex_request_o[1].operand_a[0] <= vc_issued_instr_i[1].operand_a;
                    vc_ex_request_o[1].operand_a[3:1] <= '0;
                end

            end
            else vc_ex_request_o[1] <= '0;

            vc_ex_ready_o[1] <= vc_ex_ready_i[1];

        end
    end

endmodule