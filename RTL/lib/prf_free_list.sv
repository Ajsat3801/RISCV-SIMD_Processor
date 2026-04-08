/* 
circular FIFO with first word fall through - general implementation
the head value will be the output even before pop asks for it
*/

module prf_free_list (    
    input logic clk,
    input logic reset_ni,
    
    input logic push_i,
    input instr_pkg::tag_e push_tag_i,

    input logic pop_i,
    input logic flush_i,
    
    output instr_pkg::tag_e pop_tag_o,
    output logic empty_o,
    output logic full_o
);

    localparam ADDR_SIZE = $clog2(PRF_DEPTH+1);

    T free_list[PRF_DEPTH:0]; // N+1 entry buffer
    logic[ADDR_SIZE-1:0] head, tail, head_next, tail_next; // address needs one extra bit
    logic bypass, push_allowed, pop_allowed;
    int i;

    always_comb begin

        tail_next = (tail == PRF_DEPTH) ? '0 :(tail + 1);
        head_next = (head == PRF_DEPTH) ? '0 :(head + 1);

        full_o = (tail_next == head);
        empty_o = (head == tail);

        bypass = empty_o && push_i && pop_i;
        push_allowed = push_i && (!full_o || (pop_i && !empty_o)) && !bypass;
        pop_allowed = pop_i && !empty_o && !bypass;

        if (bypass) pop_tag_o = push_tag_i;
        else if (empty_o) pop_tag_o = '0;
        else pop_tag_o = free_list[head];

    end

    always_ff @(posedge clk_i) begin

        if (!reset_ni) begin
            // 0 to 31 is committed by default, so 32 onwards stored in buffer
            for (i=32; i<PRF_DEPTH; i++) begin
                free_list[i-32] = i;
            end
            
            head <= '0;
            tail <= PRF_DEPTH-32;
        end


        else begin
            
            if (push_allowed) begin
                free_list[tail] <= push_tag_i;
                tail <= tail_next;
            end
            if (pop_allowed) begin
                head <= head_next;
            end
        end
    end

endmodule