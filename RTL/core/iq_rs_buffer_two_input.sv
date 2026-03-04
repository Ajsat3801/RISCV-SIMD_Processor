/* 
circular fifo with first word fall through - general implementation
the head value will be the output even before dequeue asks for it
*/

module iq_rs_buffer_two_input #(parameter BUFFER_SIZE = 8, parameter type T = logic[31:0])
(
    
    input logic clk,
    input logic reset_n,
    
    input logic enqueue1,
    input T enqueue1_data,

    input logic enqueue2,
    input T enqueue2_data,

    input logic dequeue,
    
    output T dequeue_data,
    output logic empty,
    output logic full,
);

localparam ADDR_SIZE = $clog2(BUFFER_SIZE+1);

T main_fifo[BUFFER_SIZE:0]; // N+1 entry buffer
logic[ADDR_SIZE-1:0] head, tail, head_next, tail_next; // address needs one extra bit

always_comb begin

    tail_next = (tail == BUFFER_SIZE) ? 0 :(tail + 1);
    tail_next_next = (tail_next == BUFFER_SIZE) ? 0 :(tail_next + 1);
    head_next = (head == BUFFER_SIZE) ? 0 :(head + 1);

    enqueue_allowed = !full || (dequeue && !empty);

    full = (tail_next == head);
    empty = head==tail;

    dequeue_data = main_fifo[head];

end

always_ff @(posedge clk) begin

    if(!reset_n) begin
        for(int j=0;j<BUFFER_SIZE;j++) begin
            main_fifo[j] <= DATA_SIZE'(j);
        end
        head <= 0;
        tail <= BUFFER_SIZE;
    end

    else begin
        if(dequeue && !empty) begin
            head <= head_next;
        end
        if(enqueue1 && enqueue2 && enqueue_allowed) begin
            main_fifo[tail] <= enqueue1_data;
            main_fifo[tail_next] <= enqueue2_data;
            tail <= tail_next_next;
        end
        else if(enqueue1 && enqueue_allowed) begin
            main_fifo[tail] <= enqueue1_data;
            tail <= tail_next;
        end
        else if(enqueue2 && enqueue_allowed) begin
            main_fifo[tail] <= enqueue2_data;
            tail <= tail_next;
        end
    end
end

endmodule