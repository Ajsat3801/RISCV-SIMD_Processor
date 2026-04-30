module ooo_arr_unit #(
    parameter logic IS_VECTOR = 1'b0
)(
    input clk_i,
    input reset_ni,
    input flush_i,

    if_dispatch_bus.arr dispatched_instr_i,
    if_retirement_bus.arr retire_instr_i,
    if_alloc_bus.arr alloc_instr_o,

    output logic arr_full_o
);

/*  ALLOCATION RENAME RETIRE UNIT
 *  Function/Behavior:
 *  ->  Maintains a list of free PRF addresses that can be assigned
 *  ->  On alloc: assign PRF space for destination arch register for each operation
 *  ->  On Retire: the PRF address is set as the destination for the arch register in commit table
 *  Parameters
 *  ->  IS_VECTOR: single bit that says whether the ARR is for scalar or vector operations
 *  Inputs
 *  ->  clk, reset_n, flush
 *  ->  instruction that needs to be allocated
 *  ->  instruction that needs to be retired
 *  Outputs
 *  ->  allocated instruction with PRF address
 *  ->  flag to indicate if arr has allocation possible
 */

    localparam FIFO_ADDR_SIZE = $clog2(PRF_DEPTH);
    typedef logic[FIFO_ADDR_SIZE] prf_fifo_addr_t;

    instr_pkg::prf_address_t reg_alloc_table  [ARCH_REG_DEPTH-1:0];
    instr_pkg::prf_address_t commit_table [ARCH_REG_DEPTH-1:0];
    instr_pkg::prf_address_t free_list[PRF_DEPTH-1:0];
    instr_pkg::prf_address_t free_list_flushed[PRF_DEPTH-1:0];
    logic[PRF_DEPTH-1:0] prf_used;

    prf_fifo_addr_t head, tail;
    prf_fifo_addr_t head_next, tail_next;
    prf_fifo_addr_t tail_flushed;

    logic head_epoch, tail_epoch;
    logic head_epoch_next, tail_epoch_next;
    logic tail_epoch_flushed;

    logic full, empty;
    logic retirement_valid, allocation_valid, allocation_op_valid;

    int i;

    always_comb begin

        // head and tail pointers for free list
        {head_epoch_next, head_next} = {head_epoch, head} + 1'b1;
        {tail_epoch_next, tail_next} = {tail_epoch, tail} + 1'b1;
        
        full  = (head == tail) && (head_epoch != tail_epoch);
        empty = (head == tail) && (head_epoch == tail_epoch);

        /* BUILDING FLUSHED STATE
         * - create a temporary free list that iterates through prf_used map and 
         *   adds an address to the free list if the prf_used is 0
         * - head is assigned to 0 and tail is updated to the tail of the temp list
         * - reg_alloc_table becomes the current state of the retire table (done
         *   in sequential block)
         */
        tail_epoch_flushed = 0;
        tail_flushed = 0;
        
        for (int i=0; i<PRF_DEPTH; i++) begin

            if (!prf_used[i]) begin
                free_list_flushed[tail_flushed] = i;
                {tail_epoch_flushed, tail_flushed} = {tail_epoch_flushed, tail_flushed} + 1'b1;
            end

        end

        /*  CONDITIONS FOR RETIREMENT TO BE VALID
         *  1)  retirment signal is valid
         *  2)  instruction to be retired writes to a register
         *  3)  destination is same type as parameter
         *  4)  destination address of the instruction is not 0
         */
        retirement_valid =  retire_instr_i.valid &&
                            retire_instr_i.write_to_reg &&
                            (retire_instr_i.dest_address != '0) && 
                            !(retire_instr_i.prf_tag.vector == IS_VECTOR);

        /*  CONDITIONS FOR ALLOCATION TO BE VALID
         *  1)  allocation signal valid
         *  2)  chip select[3] is 0, i.e. destination is a scalar register
         *  3)  instructions writes to a register
         *  4)  destination register of the instruction is not 0
         */
        allocation_valid =  dispatched_instr_i.valid &&
                            (dispatched_instr_i.instr.dest_address != '0) &&
                            (dispatched_instr_i.instr.chip_select[2] == IS_VECTOR) &&
                            dispatched_instr_i.instr.write_to_reg;

        arr_full_o = empty;

    end

    always_ff @(posedge clk_i) begin
        if (!reset_ni) begin
            /* RESET
             * Arch reg gets allocated to corresponding physical reg
             * Both commit and speculation tables are written
             * prf_used is set to 1 for 0 to arch reg and 0 for rest
             */
            for(int i=0; i<ARCH_REG_DEPTH; i++) begin
                reg_alloc_table[i] <= i;
                commit_table[i]    <= i;
                prf_used[i] <= 1'b1;
            end
            for(int i=ARCH_REG_DEPTH; i<PRF_DEPTH; i++) begin
                prf_used[i] <= 1'b0;
                free_list[i-ARCH_REG_DEPTH] <= i; 
            end
            head_epoch <= 1'b0;
            tail_epoch <= 1'b0;
            head <= '0;
            tail <= PRF_DEPTH-ARCH_REG_DEPTH;

        end
        else if (flush_i) begin
            // refer combinational block for explanation
            reg_alloc_table <= commit_table;
            free_list <= free_list_flushed;
            head <= '0;
            head_epoch <= '0;
            {tail_epoch, tail} <= {tail_epoch_flushed, tail_flushed};
            
        end
        else begin

            /* INSTRUCTION RETIREMENT
             * 1)   ROB sends the destination address and the prf tag of the instruction
             *      to be retired
             * 2)   The current prf tag of the value in destination addresss is freed i.e.
             *      its pushed into the free list & prf_used is set to 0.
             * 3)   the commit table is updated with the new prf tag & prf_used is set to 1
             */
            if (retirement_valid) begin
                prf_used[commit_table[retire_instr_i.dest_address]] <= 1'b0;
                
                free_list[tail] <= commit_table[retire_instr_i.dest_address];
                tail <= tail_next;

                commit_table[retire_instr_i.dest_address] <= retire_instr_i.prf_tag.tag;
                prf_used[retire_instr_i.prf_tag.tag] <= 1'b1;
            end

            /* INSTRUCTION ALLOCATION
             * - if allocation is valid (see comb block for conditions) assign a PRF
             *   for the instruction from the free list and add to reg_alloc_table
             * - Other instruction data sent directly without gating (to handle .vx
             *   instructions
             */
            alloc_instr_o.valid   <= dispatched_instr_i.valid;
            alloc_instr_o.rs_slot <= dispatched_instr_i.rs_slot_id;
            alloc_instr_o.instr   <= dispatched_instr_i.instr;
            alloc_instr_o.a_is_vector <= dispatched_instr_i.instr.src1_vector;
            alloc_instr_o.b_is_vector <= dispatched_instr_i.instr.src2_vector;
            
            if (allocation_valid) begin
                alloc_instr_o.prf_tag <= {IS_VECTOR, free_list[head]};

                reg_alloc_table[dispatched_instr_i.instr.dest_address] <= free_list[head];
                head <= head_next;
            end
            else alloc_instr_o.prf_tag  <= '0;
            
            alloc_instr_o.operand_a_tag <= reg_alloc_table[dispatched_instr_i.instr.src1_address];
            alloc_instr_o.operand_b_tag <= reg_alloc_table[dispatched_instr_i.instr.src2_address];

        end
    end

endmodule