/* 
circular FIFO with first word fall through - general implementation
the head value will be the output even before pop asks for it
*/

module lib_circular_fifo_fwft #(
    parameter BUFFER_SIZE = 8, 
    parameter type T = logic[31:0]
) (    
    input logic clk_i,
    input logic reset_ni,
    
    input logic push_i,
    input T push_data_i,

    input logic pop_i,
    
    output T data_o,
    output logic empty_o,
    output logic full_o,
    output logic next_full_o
);

    localparam ADDR_SIZE = $clog2(BUFFER_SIZE+1);

    T main_fifo[BUFFER_SIZE:0]; // N+1 entry buffer
    logic[ADDR_SIZE-1:0] head, tail, head_next, tail_next, tail_next_next; // address needs one extra bit
    logic bypass, push_allowed, pop_allowed;

    always_comb begin

        tail_next = (tail == BUFFER_SIZE) ? '0 : (tail + 1);
        head_next = (head == BUFFER_SIZE) ? '0 : (head + 1);

        tail_next_next = (tail_next == BUFFER_SIZE) ? '0 : (tail_next + 1);

        full_o  = (tail_next == head);
        next_full_o = (tail_next_next == head);
        empty_o = (head == tail);

        bypass = empty_o && push_i && pop_i;
        push_allowed = push_i && (!full_o || (pop_i && !empty_o)) && !bypass;
        pop_allowed  = pop_i && !empty_o && !bypass;

        if (bypass) data_o = push_data_i;
        else if (empty_o) data_o = '0;
        else data_o = main_fifo[head];

    end

    always_ff @(posedge clk_i) begin

        if (!reset_ni) begin
            head <= '0;
            tail <= '0;
        end

        else begin
            
            if (push_allowed) begin
                main_fifo[tail] <= push_data_i;
                tail <= tail_next;
            end
            if (pop_allowed) begin
                head <= head_next;
            end
        end
    end

endmodule