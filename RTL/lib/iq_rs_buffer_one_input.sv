/* 
circular FIFO with first word fall through - general implementation
the head value will be the output even before pop asks for it
*/

module iq_rs_buffer_one_input #(
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
    output logic full,
);

localparam ADDR_SIZE = $clog2(BUFFER_SIZE+1);

T main_FIFO[BUFFER_SIZE:0]; // N+1 entry buffer
logic[ADDR_SIZE-1:0] head, tail, head_next, tail_next; // address needs one extra bit

always_comb begin

    tail_next = (tail == BUFFER_SIZE) ? '0 :(tail + 1);
    head_next = (head == BUFFER_SIZE) ? '0 :(head + 1);

    full = (tail_next == head);
    empty = head==tail;

    data_out = main_FIFO[head];

end

always_ff @(posedge clk) begin

    if(!reset_n) begin
        for(int j=0;j<BUFFER_SIZE;j++) begin
            main_FIFO[j] <= DATA_SIZE'(j);
        end
        head <= '0;
        tail <= BUFFER_SIZE;
    end

    else begin
        if(pop && !empty) begin
            head <= head_next;
        end
        if(push && (!full || (pop && !empty))) begin
            main_FIFO[tail] <= push_data;
            tail <= tail_next;
        end
    end
end

endmodule