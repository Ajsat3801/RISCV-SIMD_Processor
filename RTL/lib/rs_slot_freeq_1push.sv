/* 
exact same logic as circular_fifo_fwft. only difference is reset
fills the buffer from 0 to buffer_size
*/
import config_pkg::*;

module rs_slot_freeq_1push #(
    parameter BUFFER_SIZE = 8,
    parameter type T = logic[31:0]
) (
    input logic clk,
    input logic reset_n,
    
    input logic push,
    input T push_data,

    input logic pop,
    
    output T data_out,
    output logic empty,
    output logic full
);

    localparam ADDR_SIZE = $clog2(BUFFER_SIZE+1);

    T main_fifo[BUFFER_SIZE:0]; // N+1 entry buffer
    logic[ADDR_SIZE-1:0] head, tail, head_next, tail_next; // address needs one extra bit
    logic bypass, push_allowed, pop_allowed;

    always_comb begin

        tail_next = (tail == BUFFER_SIZE) ? '0 :(tail + 1);
        head_next = (head == BUFFER_SIZE) ? '0 :(head + 1);

        full = (tail_next == head);
        empty = head==tail;

        bypass = empty && push && pop;
        push_allowed = push && (!full || (pop && !empty)) && !bypass;
        pop_allowed = pop && !empty && !bypass;

        if(bypass) data_out = push_data;
        else if(empty) data_out = '0;
        else data_out = main_fifo[head];

    end

    always_ff @(posedge clk) begin

        if(!reset_n) begin
            for(int j=0;j<BUFFER_SIZE;j++) begin
                main_fifo[j] <= DATA_SIZE'(j);
            end
            head <= '0;
            tail <= BUFFER_SIZE;
        end

        else begin
            if(push_allowed) begin
                main_fifo[tail] <= push_data;
                tail <= tail_next;
            end
            if(pop_allowed) begin
                head <= head_next;
            end
        end
    end

endmodule