/* 
 * Modification of lib_fifo_fwft_1push, ability to have 2 simultaneous pushes
 * Only one pop allowed
 *
 * Buffer has n+1 entries, but only n slots can be filled at one time
 * Next states, full and empty are calculated combinationally
 * Sequential block only updates the data to and from the buffer
*/

// import config_pkg::*;

module lib_fifo_fwft_2push #(
    parameter BUFFER_SIZE = 8,
    parameter type T = logic[31:0]
)(
    input logic clk_i,
    input logic reset_ni,
    
    input logic push1_i,
    input T push_data1_i,

    input logic push2_i,
    input T push_data2_i,

    input logic pop_i,
    
    output T data_o,
    output logic empty_o,
    output logic full_o
);

    localparam ADDR_SIZE = $clog2(BUFFER_SIZE+1);

    T main_fifo[BUFFER_SIZE:0]; // N+1 entry buffer
    logic[ADDR_SIZE-1:0] head, tail, head_next, tail_next, tail_next_next;
    logic one_slot_rem, bypass1, bypass2, pop_queue, two_enqueue, one_enqueue;

    always_comb begin

        // calculating next values of head and tail
        tail_next = (tail == BUFFER_SIZE) ? '0 :(tail + 1);
        tail_next_next = (tail_next == BUFFER_SIZE) ? '0 :(tail_next + 1);
        head_next = (head == BUFFER_SIZE) ? '0 :(head + 1);

        full_o = (tail_next == head);
        one_slot_rem = (tail_next_next == head);
        empty_o = head==tail;

        bypass1 = pop_i && push1_i && empty_o;
        bypass2 = pop_i && !push1_i && push2_i && empty_o;
        pop_queue = pop_i && !empty_o && !bypass1 && !bypass2;

        /*
        * scenarios where 2 pushes allowed
        * 1) you have 2 or more slots remaining
        * 2) you have one slot remaining + 1 pop (unlikely case)
        */
        two_enqueue = push1_i && push2_i && !full_o && (!one_slot_rem || (one_slot_rem && pop_queue));
        /*
        * scenarios where 1 push allowed
        * 1) you have 1 slot remaining
        * 2) you have no slots + 1 pop (unlikely case)
        */
        one_enqueue = !two_enqueue && (push1_i || push2_i) && (!full_o || (full_o && pop_queue));

        if(bypass1) data_o = push_data1_i;
        else if(bypass2) data_o  = push_data2_i;
        else if(!empty_o) data_o = main_fifo[head];
        else data_o = '0;

    end

    always_ff @(posedge clk_i) begin

        if (!reset_ni) begin
            head <= '0;
            tail <= '0;
        end

        else begin
            
            if(pop_queue) head <= head_next;
            
            if(two_enqueue) begin
                if(!bypass1) begin
                    main_fifo[tail] <= push_data1_i;
                    main_fifo[tail_next] <= push_data2_i;
                    tail <= tail_next_next;
                end
                else begin
                    main_fifo[tail] <= push_data2_i;
                    tail <= tail_next;
                end
            end
            
            if(one_enqueue && push1_i && !bypass1) begin
                main_fifo[tail] <= push_data1_i;
                tail <= tail_next;
            end
            else if(one_enqueue && push2_i && !bypass2) begin
                main_fifo[tail] <= push_data2_i;
                tail <= tail_next;
            end
        end
    end

endmodule