/*
modification of circular FIFO with first word fall through
only change is on reset where we do not make it empty, we set it to full
*/

module circular_FIFO_fwft #(parameter BUFFER_SIZE = 8, DATA_SIZE = 16)
(
    
    input clk,
    input reset_n,
    
    input logic enqueue,
    input logic[DATA_SIZE-1:0] enqueue_data,

    input logic dequeue,
    output logic[DATA_SIZE-1:0] dequeue_data,
    output logic empty,
    output logic full
);

localparam ADDR_SIZE = $clog2(BUFFER_SIZE+1);

logic[DATA_SIZE-1:0] main_FIFO[BUFFER_SIZE:0]; // N+1 entry buffer
logic[ADDR_SIZE-1:0] head, tail, head_next, tail_next; // address needs one extra bit

always_comb begin

    tail_next = (tail == BUFFER_SIZE) ? 0 :(tail + 1);
    head_next = (head == BUFFER_SIZE) ? 0 :(head + 1);

    full = (tail_next == head);
    empty = head==tail;

    dequeue_data = main_FIFO[head];

end

always_ff @(posedge clk) begin

    if(!reset_n) begin
        for(int j=0;j<BUFFER_SIZE;j++) begin
            main_FIFO[j] <= DATA_SIZE'(j);
        end
        head <= 0;
        tail <= BUFFER_SIZE;
    end

    else begin // body

        if(dequeue && !empty) begin
            head <= head_next;
        end
        if(enqueue && (!full || (dequeue && !empty))) begin
            main_FIFO[tail] <= enqueue_data;
            tail <= tail_next;
        end

    end

end


endmodule