/* ------------------------------------------------------------------------------------------------
 *                              INSTRUCTION QUEUE
 * ------------------------------------------------------------------------------------------------
 *
 *  Functions/Behavior:
 *  <TODO>

 *  Inputs:
 *  ->  clk, reset_n, flush
 *  ->  decoded_instr_i — Decoded instruction packet from the decode stage, to be enqueued.
 *  ->  decoded_instr_en_i — Enable qualifying decoded_instr_i.
 *  ->  instr_dispatched_i — Signal indicating an instruction has been dispatched from the RS.
 *  ->  rob_full_i — signal indicating Reorder Buffer is full.
 *  ->  arr_full_i — signal indicating ARR is full.
 *
 *  Outputs:
 *  ->  dispatched_instr_o — Dispatched instruction from head of queue.
 *  ->  queue_ready_o — 1 when queue can accept at least one more instruction.
 *
 *  Notes:
 *  <TODO>
 *
 * ------------------------------------------------------------------------------------------------
 */


module fe_instruction_queue #(
    parameter int unsigned POOL_DEPTH [config_pkg::RS_POOL_N] = '{
        config_pkg::RS_SC_ALU_DEPTH,  config_pkg::RS_MULDIV_DEPTH,
        config_pkg::RS_LSU_LOAD_DEPTH, config_pkg::RS_LSU_STORE_DEPTH,
        config_pkg::RS_BRANCH_DEPTH, config_pkg::RS_VC_ALU_DEPTH 
    },

    parameter int unsigned POOL_CREDITS [config_pkg::RS_POOL_N] = '{
        config_pkg::EX_SC_ALU_N, config_pkg::EX_MULDIV_N,
        config_pkg::EX_LSU_N, config_pkg::EX_LSU_N,
        config_pkg::EX_BRANCH_N, config_pkg::EX_VC_ALU_N}
) (

    input logic clk_i,
    input logic reset_ni,
    input logic flush_i,

    // Queue <- Decode connection
    input packet_pkg::decoded_instr_t decoded_instr_i,
    input logic decoded_instr_en_i,
    output logic queue_ready_o,

    // Queue <- RS connection for credit return
    input logic instr_dispatched_i [config_pkg::RS_DISPATCH_N],
    
    // Queue <- ARR & ROB for backpressure
    input logic rob_full_i,
    input logic arr_full_i,

    // Queue -> RS connection
    output packet_pkg::decoded_instr_t dispatched_instr_o

);

    // ---------------------------------------------------------------------------------------------
    //   Typedefs and localparams

    function automatic int unsigned max_of(input int unsigned d [config_pkg::RS_POOL_N]);
        max_of = 0;
        foreach (d[i]) if (d[i] > max_of) max_of = d[i];
    endfunction

    localparam int unsigned CNT_W = $clog2(max_of(POOL_DEPTH) + 1);
    localparam int unsigned REL_W = $clog2(max_of(POOL_CREDITS) + 1);

    typedef logic [CNT_W-1:0] cnt_t;

    localparam int unsigned PTR_W = $clog2(config_pkg::INSTR_QUEUE_DEPTH);

    typedef struct packed {
        logic epoch;
        logic [PTR_W-1:0] addr;
    } q_ptr_t;

    // ---------------------------------------------------------------------------------------------
    //   Queue status

    packet_pkg::decoded_instr_t instr_fifo[config_pkg::INSTR_QUEUE_DEPTH];
    q_ptr_t head, tail, head_next, tail_next;
    logic full, empty, full_next;

    always_comb begin
        head_next = head + 1'b1;
        tail_next = tail + 1'b1;

        full  = (head.addr == tail.addr) && (head.epoch != tail.epoch);
        empty = (head.addr == tail.addr) && (head.epoch == tail.epoch);
        full_next = (head.addr == tail_next.addr) && (head.epoch != tail_next.epoch);
    end

    // ---------------------------------------------------------------------------------------------
    //   Head Decode

    packet_pkg::decoded_instr_t head_instr;
    signal_pkg::pool_e head_pool;

    always_comb begin
        head_instr = instr_fifo[head.addr];
        case(head_instr.chip_select) 
            signal_pkg::CS_SALU : head_pool = signal_pkg::POOL_SC_ALU;
            signal_pkg::CS_MULDIV : head_pool = signal_pkg::POOL_MULDIV;
            signal_pkg::CS_BRANCH : head_pool = signal_pkg::POOL_BRANCH;
            signal_pkg::CS_VALU : head_pool = signal_pkg::POOL_VC_ALU;
            signal_pkg::CS_SLSU, signal_pkg::CS_VLSU :
                head_pool = (head_instr.operation[3]) ? signal_pkg::POOL_STORE : signal_pkg::POOL_LOAD;
            default : head_pool = signal_pkg::POOL_NONE;
        endcase
    end

    // ---------------------------------------------------------------------------------------------
    //   RS POOL counters

    cnt_t pool_cnt_q [config_pkg::RS_POOL_N];
    cnt_t pool_cnt_d [config_pkg::RS_POOL_N];

    logic[REL_W-1:0] pool_release [config_pkg::RS_POOL_N];
    logic[config_pkg::RS_POOL_N-1:0] pool_full, pool_alloc;

    always_comb begin
        int unsigned base;
        base = 0;

        for(int unsigned i = 0; i<config_pkg::RS_POOL_N; i++) begin
            pool_release[i] = '0;
            for (int unsigned c = 0; c < POOL_CREDITS[i]; c++)
                pool_release[i] += REL_W'(instr_dispatched_i[base + c]);
            base += POOL_CREDITS[i];

            pool_full[i] = pool_cnt_q[i][$clog2(POOL_DEPTH[i])];
            pool_cnt_d[i] = pool_cnt_q[i] + cnt_t'(pool_alloc[i]) - cnt_t'(pool_release[i]);
        end
    end

    always_ff @(posedge clk_i) begin
        if(!reset_ni || flush_i) begin
            for(int unsigned i=0; i<config_pkg::RS_POOL_N; i++) pool_cnt_q[i] <= '0;
        end
        else pool_cnt_q <= pool_cnt_d;
    end

    // ---------------------------------------------------------------------------------------------
    //   Enqueue and Dequeue decisions

    logic in_valid, enqueue, dequeue, upstream_ready;

    always_comb begin
        upstream_ready = !arr_full_i && !rob_full_i;
        if (empty || !head_instr.valid) dequeue = 1'b0;
        else if(head_pool == signal_pkg::POOL_NONE) dequeue = upstream_ready;
        else dequeue = upstream_ready && !pool_full[head_pool];

        pool_alloc = '0;
        if(dequeue && (head_pool != signal_pkg::POOL_NONE)) pool_alloc[head_pool] = 1'b1;

        in_valid = decoded_instr_i.valid  && decoded_instr_en_i;
        enqueue = in_valid && (!full || dequeue);

    end

    //  -------------------------------------------------------------------------------------------
    //      Queue next state

    packet_pkg::decoded_instr_t dispatched_instr_q;

    always_ff @(posedge clk_i) begin
        if(!reset_ni || flush_i) begin
            for(int unsigned i=0; i<config_pkg::INSTR_QUEUE_DEPTH; i++)
                instr_fifo[i].valid <= 1'b0;
            dispatched_instr_q <= '0;
            head <= '0;
            tail <= '0;
        end
        else begin
            if(dequeue) begin
                dispatched_instr_q <= instr_fifo[head.addr];
                head <= head_next;
            end
            else dispatched_instr_q <= '0;
            
            if(enqueue) begin
                instr_fifo[tail.addr] <= decoded_instr_i;
                tail <= tail_next;
            end
        end
    end

    //  -------------------------------------------------------------------------------------------
    //      Outputs

    assign dispatched_instr_o = (flush_i) ? '0 : dispatched_instr_q; 
    assign queue_ready_o = !(full_next || full) || dequeue;
    
endmodule