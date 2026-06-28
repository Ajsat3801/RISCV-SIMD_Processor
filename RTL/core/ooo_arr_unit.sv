/* ------------------------------------------------------------------------------------------------
 *                                  ALLOCATE-RENAME-RETIRE UNIT
 * ------------------------------------------------------------------------------------------------
 *
 *  Functions / Behavior
 *  ->  Maintains two independent rename channels for scalar & vector instructions, selected by bit
 *      [2] of chip_select.
 *  ->  Each channel holds a Register Allocation Table that maps architectural register addresses
 *      to physical register file tags.
 *  ->  A Commit Table per channel shadows the RAT and only updates on retirement, to maintain the
 *      last architecturally committed state.
 *  ->  Maintains list of available PRF tags
 *  ->  On allocation, head of free list is popped and assigned to instruction
 *  ->  on retirement, the old PRF tag from the commit table is pushed onto the tail of free-list &
        the commit table is updated to the retired tag.
 *  ->  on flush, the RAT is rolled back to the state of the commit table.
 *  ->  on writeback, PRF ready bit set to allow for dependent instructions to execute. Forwarding
 *      supported for same-cycle writeback and allocation
 *
 *  Inputs
 *  ->  clk, reset_n & flush
 *  ->  dispatched_instr_i — decoded instruction from the dispatch stage requiring rename.
 *  ->  rs_slot_id_i — reservation station slot assigned at dispatch
 *  ->  retire_instr_i — retirement bus from the ROB. 
 *  ->  sc_wb_instr_i — scalar writeback bus snooped to mark scalar PRF ready bits.
 *  ->  vc_wb_instr_i — vector writeback bus snooped to mark vector PRF ready bits.
 *
 *  Outputs
 *  ->  alloc_instr_o — renamed instruction bundle sent to the reservation station and ROB.
 *  ->  arr_full_o — stall signal asserted when scalar or vector free-list FIFO is empty.
 *
 *  Notes
 *  ->  The order in which PRF entries are allocated does not matter, used circular FIFO it becomes
 *      easy to track which entries are used without loops.
 *  ->  PRF ready bit is set immediately at allocation time for pre-calculated instructions.
 *  ->  Stores and branches are forwarded to the RS/ROB even if they produce no destination register.
 *  ->  For .vx instructions both the scalar & vector RATs are looked up combinatorially so either
 *      operand can be routed to the correct channel via src1_vector / src2_vector flags.
 *
 * ------------------------------------------------------------------------------------------------
 */

module ooo_arr_unit (
    input  logic clk_i,
    input  logic reset_ni,
    input  logic flush_i,

    input packet_pkg::decoded_instr_t dispatched_instr_i,
    input signal_pkg::rs_slot_id_t rs_slot_id_i,
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
    fifo_pointer_t sc_head_committed, sc_tail_committed;
    fifo_pointer_t vc_head_committed, vc_tail_committed;

    logic[PRF_DEPTH-1:0] sc_ready, vc_ready;

    signal_pkg::prf_address_t sc_reg_alloc_table [ARCH_REG_DEPTH];
    signal_pkg::prf_address_t vc_reg_alloc_table [ARCH_REG_DEPTH];

    signal_pkg::prf_address_t sc_commit_table [ARCH_REG_DEPTH];
    signal_pkg::prf_address_t vc_commit_table [ARCH_REG_DEPTH];

    logic sc_alloc_valid, vc_alloc_valid;
    logic sc_instr_valid, vc_instr_valid;
    logic sc_retire_valid, vc_retire_valid;
    logic sc_store_valid, vc_store_valid;
    signal_pkg::prf_tag_t sc_prf_id, vc_prf_id;

    signal_pkg::prf_address_t sc_operand_a_tag, sc_operand_b_tag;
    signal_pkg::prf_address_t vc_operand_a_tag, vc_operand_b_tag;

    always_comb begin

        // Empty when both epoch-packed pointers are identical
        arr_full_o = (sc_head == sc_tail) || (vc_head == vc_tail);

        sc_instr_valid = dispatched_instr_i.valid && (dispatched_instr_i.chip_select[2] == 1'b0);
        vc_instr_valid = dispatched_instr_i.valid && (dispatched_instr_i.chip_select[2] == 1'b1);

        sc_store_valid = sc_instr_valid && (dispatched_instr_i.operation.lsu == signal_pkg::LSU_SW);
        vc_store_valid = vc_instr_valid && (dispatched_instr_i.operation.vlsu == signal_pkg::VLSU_VSE32);

        // Allocation valid
        //   1) dispatch bus is valid
        //   2) instruction writes to a destination register or is a store
        //   3) destination is not x0
        //   4) chip_select[2] selects the channel (0 = scalar, 1 = vector)        

        sc_alloc_valid  =  sc_instr_valid 
                        && dispatched_instr_i.write_to_reg 
                        && dispatched_instr_i.dest_address != '0;
                        
        vc_alloc_valid  =  vc_instr_valid
                        && dispatched_instr_i.write_to_reg
                        && dispatched_instr_i.dest_address != '0;
                        

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
        sc_operand_a_tag = sc_reg_alloc_table[dispatched_instr_i.src1_address];
        sc_operand_b_tag = sc_reg_alloc_table[dispatched_instr_i.src2_address];
        vc_operand_a_tag = vc_reg_alloc_table[dispatched_instr_i.src1_address];
        vc_operand_b_tag = vc_reg_alloc_table[dispatched_instr_i.src2_address];

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
                sc_ready[i] <= 1'b1;
                vc_ready[i] <= 1'b1;
            end

            for (int i=ARCH_REG_DEPTH; i<PRF_DEPTH; i++) begin
                sc_free_list[i-ARCH_REG_DEPTH] <= signal_pkg::prf_address_t'(i);
                vc_free_list[i-ARCH_REG_DEPTH] <= signal_pkg::prf_address_t'(i);
                sc_ready[i] <= 1'b0;
                vc_ready[i] <= 1'b0;
            end

            sc_head <= '0;
            vc_head <= '0;
            sc_head_committed <= '0;
            vc_head_committed <= '0;

            sc_tail <= fifo_pointer_t'(PRF_DEPTH - ARCH_REG_DEPTH);
            vc_tail <= fifo_pointer_t'(PRF_DEPTH - ARCH_REG_DEPTH);

            sc_tail_committed <= fifo_pointer_t'(PRF_DEPTH - ARCH_REG_DEPTH);
            vc_tail_committed <= fifo_pointer_t'(PRF_DEPTH - ARCH_REG_DEPTH); 

            alloc_instr_o.sc_valid    <= 1'b0; 
            alloc_instr_o.vc_valid    <= 1'b0;      

        end 
        else if (flush_i) begin

            // FLUSH
            //   Restore RATs from commit tables.
            //   Snap head back to head_committed — all speculatively allocated
            //   PRFs are between head_committed and head in the free list array
            //   and are instantly reclaimed by moving the pointer.
            //   tail is untouched; retirements are permanent.

            for (int i=0; i<ARCH_REG_DEPTH; i++) begin
                // Restoring state of scalar registers

                // handling simultaneous flush + scalar retire
                if(sc_retire_valid && i == retire_instr_i.dest_address) begin
                    sc_reg_alloc_table[i] <= retire_instr_i.prf_tag.tag;
                    sc_commit_table[i]    <= retire_instr_i.prf_tag.tag;
                end
                
                else sc_reg_alloc_table[i] <= sc_commit_table[i];

                // Restoring state of vector registers
                
                // handling simultaneous flush + vector retire
                if(vc_retire_valid && i == retire_instr_i.dest_address) begin
                    vc_reg_alloc_table[i] <= retire_instr_i.prf_tag.tag;
                    vc_commit_table[i]    <= retire_instr_i.prf_tag.tag;;
                end

                else vc_reg_alloc_table[i] <= vc_commit_table[i];
            end

            // Update head and tail of scalar free list FIFO
            if(sc_retire_valid) begin
                sc_free_list[sc_tail[FIFO_WIDTH-1:0]] <= sc_commit_table[retire_instr_i.dest_address];
                sc_head <= sc_head_committed + 1'b1;
                sc_tail <= sc_tail + 1'b1;
            end
            else begin
                sc_head <= sc_head_committed;
                sc_tail <= sc_tail;
            end
            
            // Update head and tail of vector free list FIFO
            if(vc_retire_valid) begin
                vc_free_list[vc_tail[FIFO_WIDTH-1:0]] <= vc_commit_table[retire_instr_i.dest_address];
                vc_head <= vc_head_committed + 1'b1;
                vc_tail <= vc_tail + 1'b1;
            end
            else begin
                vc_head <= vc_head_committed;
                vc_tail <= vc_tail;
            end

            alloc_instr_o.sc_valid    <= 1'b0; 
            alloc_instr_o.vc_valid    <= 1'b0;

        end 
        else begin

            // WRITEBACK: mark PRF ready on execution result
            if (sc_wb_instr_i.valid) sc_ready[sc_wb_instr_i.prf_tag.tag] <= 1'b1;
            if (vc_wb_instr_i.valid) vc_ready[vc_wb_instr_i.prf_tag.tag] <= 1'b1;

            /* RETIREMENT
             *  ->  The PRF currently in the commit table for dest_address pushed to free list tail.
             *  ->  Update the commit table to the newly retired PRF tag.
             *  ->  Advance head_committed to confirm this allocation.
             */

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

            /*  ALLOCATION
             *  ->  Pass-through fields are written unconditionally (ungated on sc_alloc_valid) so that 
             *      .vx instructions still see correct operand tags on the scalar alloc bus.
             *  ->  Operand tags and ready bits select between 0 and 1 RAT/ready based on src1_vector / 
             *      src2_vector flags.
             */

            if (sc_alloc_valid) begin
                sc_reg_alloc_table[dispatched_instr_i.dest_address] <= sc_prf_id.tag;
                sc_ready[sc_prf_id.tag]  <= dispatched_instr_i.pre_calc;
                sc_head <= sc_head + 1'b1; 
            end

            if (vc_alloc_valid) begin
                vc_reg_alloc_table[dispatched_instr_i.dest_address] <= vc_prf_id.tag;
                vc_ready[vc_prf_id.tag]  <= 1'b0;
                vc_head <= vc_head + 1'b1; 
            end

            /*  ALLOCATED INSTRUCTION TO BE SENT TO SCHEDULER
             *  (Refer allocation bus for details)
             *  Scalar is valid if 
             */
            alloc_instr_o.sc_valid    <= (sc_alloc_valid || sc_store_valid) || dispatched_instr_i.is_branch; 
            alloc_instr_o.vc_valid    <= (vc_alloc_valid || vc_store_valid);
            alloc_instr_o.rs_slot_id  <= rs_slot_id_i;
            alloc_instr_o.instr       <= dispatched_instr_i;
            alloc_instr_o.a_is_vector <= dispatched_instr_i.src1_vector;
            alloc_instr_o.b_is_vector <= dispatched_instr_i.src2_vector;

            if(dispatched_instr_i.src1_vector) begin
                alloc_instr_o.operand_a_tag   <= '{vector: 1'b1, tag: vc_operand_a_tag};
                alloc_instr_o.operand_a_ready <= vc_ready[vc_operand_a_tag] || 
                        (vc_alloc_valid && (vc_wb_instr_i.prf_tag.tag == vc_operand_a_tag));
            end
            else begin
                alloc_instr_o.operand_a_tag   <= '{vector: 1'b0, tag: sc_operand_a_tag};
                alloc_instr_o.operand_a_ready <= sc_ready[sc_operand_a_tag] || 
                        (sc_alloc_valid && (sc_wb_instr_i.prf_tag.tag == sc_operand_a_tag));
            end

            if(dispatched_instr_i.src2_vector) begin
                alloc_instr_o.operand_b_tag   <= '{vector: 1'b1, tag: vc_operand_b_tag};
                alloc_instr_o.operand_b_ready <= vc_ready[vc_operand_b_tag] || 
                        (vc_alloc_valid && (vc_wb_instr_i.prf_tag.tag == vc_operand_b_tag));
            end
            else begin
                alloc_instr_o.operand_b_tag   <= '{vector: 1'b0, tag: sc_operand_b_tag};
                alloc_instr_o.operand_b_ready <= sc_ready[sc_operand_b_tag] || 
                        (sc_alloc_valid && (sc_wb_instr_i.prf_tag.tag == sc_operand_b_tag));
            end

            case(1) 
                sc_alloc_valid: alloc_instr_o.prf_tag <= sc_prf_id;
                vc_alloc_valid: alloc_instr_o.prf_tag <= vc_prf_id;
                default: begin
                    alloc_instr_o.prf_tag.vector <= vc_instr_valid;
                    alloc_instr_o.prf_tag.tag <= '0;
                end
            endcase

            alloc_instr_o.precalc_valid   <= sc_alloc_valid && dispatched_instr_i.pre_calc;
            alloc_instr_o.precalc_prf_tag <= (sc_alloc_valid) ? sc_prf_id : '0;

        end
    end

endmodule