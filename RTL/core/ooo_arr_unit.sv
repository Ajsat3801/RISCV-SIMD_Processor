/*  ALLOCATION RENAME RETIRE UNIT
 *
 *  Two channels are maintained: 0 (scalar, index 0) and 1 (vector, index 1).
 *  The RATs and commit tables are kept as separate named arrays per channel.
 *  All free-list infrastructure is unified into [2]-indexed arrays.
 *
 *  Free list is a circular FIFO.  head advances on allocation (speculative),
 *  tail advances on retirement (permanent).  head_committed is a shadow of
 *  head that only advances on retirement, tracking the last confirmed state.
 *  On flush, head is restored to head_committed — no scanning required and
 *  no prf_used bitmap is needed.
 *
 *  Inputs
 *    dispatched_instr_i  — instruction from dispatch needing rename
 *    retire_instr_i      — instruction being retired from ROB
 *    sc_wb_instr_i       — scalar writeback (marks PRF ready)
 *    vc_wb_instr_i       — vector writeback (marks PRF ready)
 *  Outputs
 *    alloc_instr_o       — renamed instruction to RS / ROB
 *    precalc_*           — pre-calculated result for scalar ops (lui, auipc, branches, jal)
 *    arr_full_o          — stall: free list empty on either channel
 */

//import config_pkg::*;
module ooo_arr_unit (
    input  logic clk_i,
    input  logic reset_ni,
    input  logic flush_i,

    if_dispatch_bus.arr dispatched_instr_i,
    if_retirement_bus.arr retire_instr_i,
    if_data_bus.snoop sc_wb_instr_i,
    if_data_bus.snoop vc_wb_instr_i,
    if_alloc_bus.arr alloc_instr_o,

    output logic arr_full_o
);

    // {epoch[FIFO_WIDTH], ptr[FIFO_WIDTH-1:0]}
    localparam int FIFO_WIDTH = $clog2(PRF_DEPTH); 
    typedef logic [FIFO_WIDTH:0] fifo_pointer_t;  

    signal_pkg::prf_address_t sc_free_list[PRF_DEPTH];
    signal_pkg::prf_address_t vc_free_list[PRF_DEPTH];

    fifo_pointer_t sc_head, vc_head;
    fifo_pointer_t sc_tail, vc_tail; 
    fifo_pointer_t sc_head_committed, vc_tail_committed;

    logic[PRF_DEPTH-1:0] sc_ready, vc_ready;

    signal_pkg::prf_address_t sc_reg_alloc_table [ARCH_REG_DEPTH];
    signal_pkg::prf_address_t vc_reg_alloc_table [ARCH_REG_DEPTH];

    signal_pkg::prf_address_t sc_commit_table [ARCH_REG_DEPTH];
    signal_pkg::prf_address_t vc_commit_table [ARCH_REG_DEPTH];

    logic sc_alloc_valid, vc_alloc_valid;
    logic sc_retire_valid, vc_retire_valid;
    signal_pkg::prf_tag_t sc_prf_id, vc_prf_id;

    signal_pkg::prf_address_t sc_operand_a_tag, sc_operand_b_tag;
    signal_pkg::prf_address_t vc_operand_a_tag, vc_operand_b_tag;

    always_comb begin

        // Empty when both epoch-packed pointers are identical
        arr_full_o = (sc_head == sc_tail) || (vc_head == vc_tail);

        // Allocation valid
        //   1) dispatch bus is valid
        //   2) instruction writes to a destination register
        //   3) destination is not x0
        //   4) chip_select[2] selects the channel (0 = scalar, 1 = vector)

        sc_alloc_valid = dispatched_instr_i.valid
                      && dispatched_instr_i.instr.write_to_reg
                      && (dispatched_instr_i.instr.dest_address != '0)
                      && (dispatched_instr_i.instr.chip_select[2] == 1'b0);

        vc_alloc_valid = dispatched_instr_i.valid
                      && dispatched_instr_i.instr.write_to_reg
                      && (dispatched_instr_i.instr.dest_address != '0)
                      && (dispatched_instr_i.instr.chip_select[2] == 1'b1);

        // Retirement valid
        //   1) retire bus is valid
        //   2) instruction writes to a register
        //   3) destination is not x0 / v0
        //   4) prf_tag.vector selects the channel

        sc_retire_valid = retire_instr_i.valid
                       && retire_instr_i.write_to_reg
                       && (retire_instr_i.dest_address != '0)
                       && (retire_instr_i.prf_tag.vector == 1'b0);

        vc_retire_valid = retire_instr_i.valid
                       && retire_instr_i.write_to_reg
                       && (retire_instr_i.dest_address != '0)
                       && (retire_instr_i.prf_tag.vector == 1'b1);

        // Next PRF to be assigned sits at the head of each channel's free list
        sc_prf_id = '{vector: 1'b0, tag: sc_free_list[sc_head[FIFO_WIDTH-1:0]]};
        vc_prf_id = '{vector: 1'b1, tag: vc_free_list[vc_head[FIFO_WIDTH-1:0]]};

        // RAT lookups for both channels (needed to resolve .vx mixed operands)
        sc_operand_a_tag = sc_reg_alloc_table[dispatched_instr_i.instr.src1_address];
        sc_operand_b_tag = sc_reg_alloc_table[dispatched_instr_i.instr.src2_address];
        vc_operand_a_tag = vc_reg_alloc_table[dispatched_instr_i.instr.src1_address];
        vc_operand_b_tag = vc_reg_alloc_table[dispatched_instr_i.instr.src2_address];

    end

    always_ff @(posedge clk_i) begin

        // RESET
        //   arch reg i maps to PRF i for both channels.
        //   Free list is loaded with PRF[ARCH_REG_DEPTH .. PRF_DEPTH-1].
        //   All PRFs start ready (reset values are architecturally valid).

        if (!reset_ni) begin

            for (int i=0; i<ARCH_REG_DEPTH; i++) begin
                sc_reg_alloc_table[i] <= signal_pkg::prf_address_t'(i);
                vc_reg_alloc_table[i] <= signal_pkg::prf_address_t'(i);
                sc_commit_table[i]    <= signal_pkg::prf_address_t'(i);
                vc_commit_table[i]    <= signal_pkg::prf_address_t'(i);
            end

            for (int i=ARCH_REG_DEPTH; i<PRF_DEPTH; i++) begin
                sc_free_list[i-ARCH_REG_DEPTH] <= signal_pkg::prf_address_t'(i);
                vc_free_list[i-ARCH_REG_DEPTH] <= signal_pkg::prf_address_t'(i);
            end

            sc_head <= '0;
            vc_head <= '0;

            sc_tail <= fifo_pointer_t'(PRF_DEPTH - ARCH_REG_DEPTH);
            vc_tail <= fifo_pointer_t'(PRF_DEPTH - ARCH_REG_DEPTH);

            sc_ready <= '1;
            vc_ready <= '1;

        // FLUSH
        //   Restore RATs from commit tables.
        //   Snap head back to head_committed — all speculatively allocated
        //   PRFs are between head_committed and head in the free list array
        //   and are instantly reclaimed by moving the pointer.
        //   tail is untouched; retirements are permanent.

        end 
        else if (flush_i) begin

            for (int i=0; i<ARCH_REG_DEPTH; i++) begin
                sc_reg_alloc_table[i] <= sc_commit_table[i];
                vc_reg_alloc_table[i] <= vc_commit_table[i];
            end

            sc_head <= head_committed[0];
            vc_head <= head_committed[1];

        end 
        else begin

            // WRITEBACK: mark PRF ready on execution result
            if (sc_wb_instr_i.valid) sc_ready[sc_wb_instr_i.prf_tag.tag] <= 1'b1;
            if (vc_wb_instr_i.valid) vc_ready[vc_wb_instr_i.prf_tag.tag] <= 1'b1;

            // RETIREMENT
            //   1) The PRF currently in the commit table for dest_address is
            //      now superseded — push it onto the free list tail.
            //   2) Update the commit table to the newly retired PRF tag.
            //   3) Advance head_committed to confirm this allocation.

            if (sc_retire_valid) begin
                sc_free_list[sc_tail[FIFO_WIDTH-1:0]] <= sc_commit_table[retire_instr_i.dest_address];
                sc_tail <= sc_tail + 1'b1;
                sc_commit_table[retire_instr_i.dest_address] <= retire_instr_i.prf_tag.tag;
                sc_head_committed <= sc_head_committed + 1'b1;
            end

            if (vc_retire_valid) begin
                vc_free_list[vc_tail[FIFO_WIDTH-1:0]] <= vc_commit_table[retire_instr_i.dest_address];
                vc_tail <= vc_tail + 1'b1;
                vc_commit_table[retire_instr_i.dest_address] <= retire_instr_i.prf_tag.tag;
                vc_head_committed <= vc_head_committed + 1'b1;
            end

             // ALLOCATION
            // Pass-through fields are written unconditionally (ungated on
            // sc_alloc_valid) so that .vx instructions — which have a scalar
            // destination but may carry vector source operands — still see
            // correct operand tags on the scalar alloc bus.
            //
            // Operand tags and ready bits select between 0 and 1 RAT/ready
            // based on src1_vector / src2_vector flags.

            if (sc_alloc_valid) begin
                sc_reg_alloc_table[dispatched_instr_i.instr.dest_address] <= sc_prf_id.tag;
                sc_ready[sc_prf_id.tag]  <= !dispatched_instr_i.instr.pre_calc;
                sc_head <= sc_head + 1'b1; 
            end

            if (vc_alloc_valid) begin
                vc_reg_alloc_table[dispatched_instr_i.instr.dest_address] <= vc_prf_id.tag;
                vc_ready[vc_prf_id.tag]  <= !dispatched_instr_i.instr.pre_calc;
                vc_head <= vc_head + 1'b1; 
            end

            // Alloc output
            alloc_instr_o.sc_valid   <= sc_alloc_valid && !dispatched_instr_i.instr.pre_calc; 
            alloc_instr_o.vc_valid   <= vc_alloc_valid && !dispatched_instr_i.instr.pre_calc;
            alloc_instr_o.rs_slot_id <= dispatched_instr_i.rs_slot_id;
            alloc_instr_o.instr      <= dispatched_instr_i.instr;
            alloc_instr_o.operand_a_is_vector <= dispatched_instr_i.instr.src1_vector;
            alloc_instr_o.operand_b_is_vector <= dispatched_instr_i.instr.src2_vector;

            if(dispatched_instr_i.instr.src1_vector) begin
                alloc_instr_o.operand_a_tag   <= '{vector: 1'b1, tag: vc_operand_a_tag};
                alloc_instr_o.operand_a_ready <= vc_ready[vc_operand_a_tag];
            end
            else begin
                alloc_instr_o.operand_a_tag   <= '{vector: 1'b0, tag: sc_operand_a_tag};
                alloc_instr_o.operand_a_ready <= sc_ready[sc_operand_a_tag];
            end

            if(dispatched_instr_i.instr.src2_vector) begin
                alloc_instr_o.operand_b_tag   <= '{vector: 1'b1, tag: vc_operand_b_tag};
                alloc_instr_o.operand_b_ready <= vc_ready[vc_operand_b_tag];
            end
            else begin
                alloc_instr_o.operand_b_tag   <= '{vector: 1'b0, tag: sc_operand_b_tag};
                alloc_instr_o.operand_b_ready <= sc_ready[sc_operand_b_tag];
            end

            case(1) 
                sc_alloc_valid: alloc_instr_o.prf_tag <= sc_prf_id;
                vc_alloc_valid: alloc_instr_o.prf_tag <= vc_prf_id;
                default: alloc_instr_o.prf_tag <= '0;
            endcase

            alloc_instr_o.precalc_valid   <= sc_alloc_valid && dispatched_instr_i.instr.pre_calc;
            alloc_instr_o.precalc_prf_tag <= (sc_alloc_valid) ? sc_prf_id : '0;

        end
    end

endmodule