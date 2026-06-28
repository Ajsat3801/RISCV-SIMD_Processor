/* ------------------------------------------------------------------------------------------------
 *                              INSTRUCTION QUEUE
 * ------------------------------------------------------------------------------------------------
 *
 *  Functions/Behavior:
 *  ->  Maintains queue of instructions that are ready to dispatch
 *  ->  Keeps a FIFO of available slots of each reservation station
 *  ->  Enqueue if instruction is valid
 *  ->  3 conditions for dequeue
 *      1) FIFO is not empty
 *      2) RS slot is available for the instruction at head of FIFO
 *      3) ROB is not full
 *  ->  Refer to module definition of RS slot FIFO for behavior of RS slot FIFO
 *  ->  On flush or reset all FIFO entries, pointers & outputs cleared to zero. RS slot free queues
 *      also reset on flush.
 *  ->  Signals upstream readiness via queue_ready_o, 0 when FIFO is full or will be full next cycle
 *      unless a simultaneous dequeue creates room.

 *  Inputs:
 *  ->  clk, reset_n, flush
 *  ->  decoded_instr_i — Decoded instruction packet from the decode stage, to be enqueued.
 *  ->  decoded_instr_en_i — Enable qualifying decoded_instr_i.
 *  ->  released_rs_slot_id_i — Array of RS slot IDs being freed by completing execution units, one
 *      per dispatch channel.
 *  ->  rs_slot_released_i — Valid flags for released_rs_slot_id_i.
 *  ->  rob_full_i — signal indicating Reorder Buffer is full.
 *  ->  arr_full_i — signal indicating ARR is full.
 *
 *  Outputs:
 *  ->  dispatched_instr_o — Dispatched instruction from head of queue.
 *  ->  rs_slot_id_o — RS slot ID allocated to the dispatched instruction.
 *  ->  queue_ready_o — 1 when queue can accept at least one more instruction.
 *
 *  Notes:
 *  ->  Head and tail use an epoch+address struct pointer scheme.
 *  ->  queue_ready_o deasserts one cycle before the FIFO fills.
 *  ->  NOP instructions bypass the RS slot availability check and sent directly to ROB if valid.
 *  ->  Both CS_SLSU and CS_VLSU share the same resource. Separated for decoding uniformity
 *  ->  Slot repopulation after a flush is driven externally via rs_slot_released_i.
 *  ->  Buffer overflow is not handled internally. The decoder is responsible for halting valid
 *      instruction input when queue_ready_o is 0.

 *  Future Improvements:
 *   -> Implement bypass and remove 1 cycle lag when queue is empty
 *
 * ------------------------------------------------------------------------------------------------
 */


module fe_instruction_queue (

    input logic clk_i,
    input logic reset_ni,
    input logic flush_i,

    input packet_pkg::decoded_instr_t decoded_instr_i,
    input logic decoded_instr_en_i,
    input signal_pkg::rs_slot_id_t released_rs_slot_id_i [RS_DISPATCH_COUNT-1:0],
    input logic rs_slot_released_i [RS_DISPATCH_COUNT-1:0],
    
    input logic rob_full_i,
    input logic arr_full_i,

    output packet_pkg::decoded_instr_t dispatched_instr_o,
    output signal_pkg::rs_slot_id_t rs_slot_id_o,
    output logic queue_ready_o
);

    typedef enum logic[2:0] {IDX_ALU, IDX_MULDIV, IDX_LSU, IDX_BRANCH, IDX_VALU, IDX_NOP} rs_index_e;
    
    localparam int unsigned INSTRUCTION_QUEUE_PTR_LEN = $clog2(INSTRUCTION_QUEUE_LEN);
    typedef struct packed {logic epoch; logic[INSTRUCTION_QUEUE_PTR_LEN-1:0] address;} q_ptr_t;

    // RS Slot tracking buffer
    signal_pkg::rs_slot_id_t next_rs_slot[RS_COUNT-1:0];
    logic[RS_COUNT-1:0] rs_full, rs_empty, dequeue_rs_fifo;

    // Instruction FIFO
    packet_pkg::decoded_instr_t instr_fifo[INSTRUCTION_QUEUE_LEN-1:0];
    q_ptr_t head, tail, head_next, tail_next, tail_next_next;
    logic full, empty, enqueue, dequeue, upstream_ready, full_next, in_valid;

    // intermediate variables
    rs_index_e rs_index;
    logic reset_wb_n;
    packet_pkg::decoded_instr_t dispatched_instr_q;

    lib_rs_slot_freeq_2push #(
        .BUFFER_SIZE(16),
        .T(logic[RS_ADDR_W-1:0])
    ) alu_fifo (
        .clk_i(clk_i),
        .reset_ni(reset_wb_n),
        .push1_i(rs_slot_released_i[0]),
        .push_data1_i(released_rs_slot_id_i[0]),
        .push2_i(rs_slot_released_i[1]),
        .push_data2_i(released_rs_slot_id_i[1]),
        .pop_i(dequeue_rs_fifo[0]),
        .data_o(next_rs_slot[0]),
        .empty_o(rs_empty[0]),
        .full_o(rs_full[0])
    );

    lib_rs_slot_freeq_1push #(
        .BUFFER_SIZE(8),
        .T(logic[RS_ADDR_W-1:0])
    ) muldiv_fifo (
        .clk_i(clk_i),
        .reset_ni(reset_wb_n),
        .push_i(rs_slot_released_i[2]),
        .push_data_i(released_rs_slot_id_i[2]),
        .pop_i(dequeue_rs_fifo[1]),
        .data_o(next_rs_slot[1]),
        .empty_o(rs_empty[1]),
        .full_o(rs_full[1])
    );
    
    lib_rs_slot_freeq_1push #(
        .BUFFER_SIZE(8),
        .T(logic[RS_ADDR_W-1:0])
    ) lsu_fifo (
        .clk_i(clk_i),
        .reset_ni(reset_wb_n),
        .push_i(rs_slot_released_i[3]),
        .push_data_i(released_rs_slot_id_i[3]),
        .pop_i(dequeue_rs_fifo[2]),
        .data_o(next_rs_slot[2]),
        .empty_o(rs_empty[2]),
        .full_o(rs_full[2])
    );

    lib_rs_slot_freeq_1push #(
        .BUFFER_SIZE(8),
        .T(logic[RS_ADDR_W-1:0])
    ) branch_fifo (
        .clk_i(clk_i),
        .reset_ni(reset_wb_n),
        .push_i(rs_slot_released_i[4]),
        .push_data_i(released_rs_slot_id_i[4]),
        .pop_i(dequeue_rs_fifo[3]),
        .data_o(next_rs_slot[3]),
        .empty_o(rs_empty[3]),
        .full_o(rs_full[3])
    );
    
    lib_rs_slot_freeq_1push #(
        .BUFFER_SIZE(8),
        .T(logic[RS_ADDR_W-1:0])
    ) valu_fifo (
        .clk_i(clk_i),
        .reset_ni(reset_wb_n),
        .push_i(rs_slot_released_i[5]),
        .push_data_i(released_rs_slot_id_i[5]),
        .pop_i(dequeue_rs_fifo[4]),
        .data_o(next_rs_slot[4]),
        .empty_o(rs_empty[4]),
        .full_o(rs_full[4])
    );

    always_comb begin
        dequeue_rs_fifo = '0;

        {head_next.epoch, head_next.address} = {head.epoch, head.address} + 1'b1;
        {tail_next.epoch, tail_next.address} = {tail.epoch, tail.address} + 1'b1;

        full  = (head.address == tail.address) && (head.epoch != tail.epoch);
        empty = (head.address == tail.address) && (head.epoch == tail.epoch);

        full_next  = (head.address == tail_next.address) && (head.epoch != tail_next.epoch);

        upstream_ready = !rob_full_i && !arr_full_i;

        case(instr_fifo[head.address].chip_select)
            signal_pkg::CS_SALU   : rs_index = IDX_ALU;
            signal_pkg::CS_MULDIV : rs_index = IDX_MULDIV;
            signal_pkg::CS_BRANCH : rs_index = IDX_BRANCH;
            signal_pkg::CS_SLSU   : rs_index = IDX_LSU;
            signal_pkg::CS_VALU   : rs_index = IDX_VALU;
            signal_pkg::CS_VLSU   : rs_index = IDX_LSU;
            default   : rs_index = IDX_NOP;
        endcase

        if (!empty && instr_fifo[head.address].valid ) begin
            if (rs_index != IDX_NOP) begin
                dequeue  = !rs_empty[rs_index] && upstream_ready;
                dequeue_rs_fifo[rs_index] = dequeue;
            end
            else dequeue = upstream_ready;
        end
        else dequeue = 1'b0;
        in_valid = decoded_instr_i.valid && decoded_instr_en_i;
        enqueue    = (!full || dequeue) && in_valid;
        reset_wb_n = (reset_ni && !flush_i) ;

        queue_ready_o = !(full_next || full )|| dequeue;
        
    end

    always_comb begin
        dispatched_instr_o = (!flush_i) ? dispatched_instr_q : '0;
    end

    always_ff @(posedge clk_i) begin
        if (!reset_ni || flush_i) begin

            for (int i=0; i<INSTRUCTION_QUEUE_LEN; i++) instr_fifo[i] <= '0;

            dispatched_instr_q <= '0;
            rs_slot_id_o  <= '0;
            head <= '0;
            tail <= '0;
        end

        else begin
            if (dequeue) begin
                 dispatched_instr_q <= instr_fifo[head.address];
                rs_slot_id_o  <= next_rs_slot[rs_index];
                head <= head_next;
            end
            else begin 
                 dispatched_instr_q <= '0;
                rs_slot_id_o  <= '0;
            end
            if (enqueue) begin
                instr_fifo[tail.address] <= decoded_instr_i;
                tail <= tail_next;
            end
        end
    end
    
endmodule