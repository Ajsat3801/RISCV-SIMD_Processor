import config_pkg::*;

module instruction_queue #()(
/*
 * Inputs
 *    - clk, reset_n
 *    - decoded instruction from decode
 *    - array of RS slots released. Length of array is same as number of ex units
 *    - array of flag bits to indicate if an RS slot is released
 *    - signal indicating availability of ROB 
 */
    input logic clk_i,
    input logic reset_ni,

    input instr_pkg::decoded_instr_t decoded_instr_i,
    input instr_pkg::rs_slot_id_t rs_slot_released_id_i [NUMBER_OF_EX-1:0],
    input logic rs_released_i [NUMBER_OF_EX-1:0]
    
    input rob_full_i;
/*
 * Outputs
 *    - signal to decoder indicating availability of slot in FIFO
 *    - allocated instruction and RS slot sent to instruction bus
 */
    instruction_bus_if.queue alloc_instr_o,
    output queue_ready_o,
);

/* 
 *Functions 
 *   1) Maintains queue of instructions that are ready to dispatch
 *   2) Keeps a FIFO of available slots of each reservation station
 * 
 * Behavior
 *   -  Enqueue if instruction is valid
 *   -  3 conditions for dequeue
 *      1) FIFO is not empty
 *      2) RS slot is available for the instruction at head of FIFO
 *      3) ROB is not full
 *   -  Refer to module definition of RS slot FIFO for behavior of RS slot FIFO
 * 
 * Notes 
 *    - Buffer full scenario is not handled as its assumed no valid input occurs
 *      when the buffer is full. Handled by decoder
 *    - Number of entries in the fifo is 1 more than the buffer size for simpler logic
 *    - If chip select is 1 we check 0th RS fifo. chip select 0 is a NOP
 */

    // RS Slot tracking buffer
    instr_pkg::rs_slot_id_t next_rs_slot[NUMBER_OF_RS-1:0];
    logic[NUMBER_OF_RS-1:0] rs_full, rs_empty, dequeue_rs_fifo;

    // Instruction FIFO
    instr_pkg::decoded_instr_t instr_fifo[INSTRUCTION_QUEUE_LEN:0]; // N+1 entry buffer
    logic[INSTRUCTION_QUEUE_PTR_LEN-1:0] head, tail, head_next, tail_next;
    logic full, empty, enqueue, dequeue;

    // output flip flops
    instr_pkg::decoded_instr_t alloc_instr_q;
    instr_pkg::rs_slot_id_t rs_slot_id_q;

    // intermediate variables
    logic[RS_IDX_W-1:0] rs_index;
    instr_pkg::chip_select_e cs;

    rs_slot_freeq_2push #(.BUFFER_SIZE(16), .T(logic[RS_ADDR_W-1:0])) alu_fifo (
        .clk_i(clk_i),
        .reset_ni(reset_ni),
        .push1_i(rs_released_i[0]),
        .push_data1_i(rs_slot_released_id_i[0]),
        .push2_i(rs_released_i[1]),
        .push_data2_i(rs_slot_released_id_i[1]),
        .pop_o(dequeue_rs_fifo[0]),
        .data_out_o(next_rs_slot[0]),
        .empty_o(rs_empty[0]),
        .full_o(rs_full[0]),
    );

    /* FIFOs to cater for future EX units

    rs_slot_freeq_1push #(.BUFFER_SIZE(8), .T(logic[RS_ADDR_W-1:0])) muldiv_fifo (
        .clk_i(clk_i),
        .reset_ni(reset_ni),
        .push_i(rs_released_i[2]),
        .push_data_i(rs_slot_released_id_i[2]),
        .pop_o(dequeue_rs_fifo[1]),
        .data_out_o(next_rs_slot[1]),
        .empty_o(rs_empty[1]),
        .full_o(rs_full[1]),
    );

    rs_slot_freeq_1push #(.BUFFER_SIZE(8), .T(logic[RS_ADDR_W-1:0])) lsu_fifo (
        .clk_i(clk_i),
        .reset_ni(reset_ni),
        .push_i(rs_released_i[3]),
        .push_data_i(rs_slot_released_id_i[3]),
        .pop_o(dequeue_rs_fifo[2]),
        .data_out_o(next_rs_slot[2]),
        .empty_o(rs_empty[2]),
        .full_o(rs_full[2]),
    );
    */

    always_comb begin

        dequeue_rs_fifo = '0;
        dequeue = 1'b0;
        enqueue = 1'b0;
        rs_index = '0;
        
        tail_next = (tail == INSTRUCTION_QUEUE_LEN) ? 0 :(tail + 1);
        head_next = (head == INSTRUCTION_QUEUE_LEN) ? 0 :(head + 1);

        full = (tail_next == head);
        empty = head==tail;

        cs = instr_fifo[head].chip_select;

        if (!empty && instr_fifo[head].valid ) begin
            if (cs!=0 && cs<NUMBER_OF_RS) begin
                rs_index = instr_fifo[head].chip_select - 1;
                dequeue = !rs_empty[rs_index] && !rob_full_i;
                dequeue_rs_fifo[rs_index] = dequeue;
            end
            else begin
                dequeue = !rob_full_i;
                dequeue_rs_fifo = '0;
            end
        end

        enqueue = (!full || dequeue) && decoded_instr_i.valid;
        
    end

    always_ff @(posedge clk_i) begin
        if (!reset_ni) begin
            alloc_instr_q <= '0;
            rs_slot_id_q <= '0;
            head <= '0;
            tail <= '0;
        end

        else begin

            if (dequeue) begin
                alloc_instr_q <= instr_fifo[head];
                rs_slot_id_q <= next_rs_slot[rs_index];
                head <= head_next;
            end
            else begin 
                alloc_instr_q <= '0;
                rs_slot_id_q <= '0;
            end

            if (enqueue) begin
                instr_fifo[tail] <= decoded_instr_i;
                tail <= tail_next;
            end

        end
    end

    assign alloc_instr_o.valid = alloc_instr_q.valid;
    assign alloc_instr_o.decoded_instr = alloc_instr_q;
    assign alloc_instr_o.rs_slot_id = rs_slot_id_q;

    assign queue_ready_o = (!full || dequeue);

endmodule