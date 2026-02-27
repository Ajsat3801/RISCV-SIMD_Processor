/*  
Arbiter for writeback
Takes inputs from all the EX units and sends one instruction per cycle to CDB

*/
/* 
    xxxx_q_count counts till n-1 values
    xxxx_q_full acts as an overflow as well as a queue full flag
    
    ENQUEUE LOGIC:
        if ( q_full == 0){
            q[tail] <= input;
            tail <= (tail + 1) % 8;
            if (q_count == all ones) q_full = 1;
            else q_count = q_count + 1;
            q_empty = 0;
        } 
    
    DEQUEUE LOGIC:

        if(q_empty == 0){
            output <= queue[head];
            head <= (head + 1) % 8;
            if (q_full  == 1) q_full = 0;
            else q_count = q_count - 1;
            if(q_count == 0) q_empty = 1;
        }
*/

module writeback_arbiter #(parameter NUM_EX=2) (
    input logic clk,
    input logic reset_n,

    // EX units
    input signal_pkg::ex_to_wb_signal_t ex_result[NUM_EX],
    output logic wb_ready[NUM_EX],

    input signal_pkg::ex_to_wb_signal_t lsu_result, 
    output logic wb_ready_lsu;

    common_data_bus_if.writeback cdb_data
);

storage_pkg::wb_queue_entry_t wb_result; 
storage_pkg::wb_queue_entry_t fifo_heads[NUM_EX-1:0]; 
logic[clog2(NUM_EX)-1:0] choice = 'd0;
logic[NUM_EX-1:0] empty, full, dequeue;


// LSU treated seperately with top priority to minimize memory latency

always_comb begin

    // dequeue must be a single enabled bit in the array
    if(lsu_result.valid) dequeue = 'd0;


end

circular_FIFO_fwft  #(.BUFFER_SIZE(NUM_EX), .T(storage_pkg::wb_queue_entry_t)) alu_fifo (
    .clk(clk),
    .reset_n(reset_n),
    .enqueue(ex_result[0].valid),
    .enqueue_data(ex_result[0]),
    .dequeue(dequeue[0]),
    .dequeue_data(fifo_heads[0]),
    .empty(empty[0]),
    .full(full[0])
);

always_ff @(posedge clk) begin

    if(!reset_n) begin

    end

    else begin
        if(lsu_result_valid) wb_result <= lsu_result;
        else begin
            
        end

    end

end

assign cdb_data = 

endmodule