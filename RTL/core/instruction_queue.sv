/*
    instruction queue - circular FIFO that accumulates and 
    sends one instruction at a time to the ARR pipeline

    Notes:

*/


`include "typedefs.sv"
import instr_desc::*;

module instruction_queue #(parameter FIFO_LEN=16,RS_LEN=8,NUM_RS=2)(
    input logic clk,
    input logic reset_n,

    // inputs from decode
    input decoded_instr_t decoded_instr,
    output queue_ready,

    // array of inputs from Reservation Stations
    input logic[($clog2(RS_LEN)*NUM_RS)-1:0] rs_slot_released_id,
    input logic[NUM_RS-1:0] rs_released

    // outputs to instruction bus
    output IQ_ROB_t alloc_instr_ROB;
    output IQ_RAT_t alloc_instr_RAT;
    output IQ_Reg_t alloc_instr_Reg;

    input ROB_full;

);

localparam RS_ADDR_LEN = $clog2(RS_LEN);
localparam FIFO_PTR_LEN = $clog2(FIFO_LEN+1);
localparam int RS_IDX_W = (NUM_RS<=2) ? 1 : $clog2(NUM_RS);

// RS Slot tracking buffer
// NOTE: track chip_select-1 field for each RS; CS=0 dont do anything
logic[RS_ADDR_LEN-1:0] next_rs_slot[NUM_RS-1:0];
logic[NUM_RS-1:0] rs_full, rs_empty, dequeue_rs_fifo;

// Instruction FIFO
decoded_instr_t instr_fifo[FIFO_LEN:0]; // N+1 entry buffer
logic[FIFO_PTR_LEN-1:0] head, tail, head_next, tail_next;
logic full, empty, enqueue, dequeue;

// output flip flops
decoded_instr_t alloc_instr_q;
logic[RS_ADDR_LEN-1:0] rs_slot_id_q;

logic[RS_IDX_W-1:0] rs_index;
chip_select_e cs;

genvar i;
generate
    for(i=0; i<NUM_RS; i++) begin
        circular_FIFO_fwft #(BUFFER_SIZE = RS_LEN, DATA_SIZE = RS_ADDR_LEN) rs_fifo (
            .clk(clk),
            .reset_n(reset_n),
            .enqueue(rs_released[i]),
            .enqueue_data(rs_slot_released_id[((i+1)*RS_ADDR_LEN)-1:i*RS_ADDR_LEN]),
            .dequeue(dequeue_rs_fifo[i]),
            .dequeue_data(next_rs_slot[i]),
            .empty(rs_empty[i]),
            .full(rs_full[i])
        )
    end

endgenerate

// enqueue if instruction is valid
// dequeue if buffer isnt empty && rs slot available for head of buffer

always_comb begin

    dequeue_rs_fifo = 'd0;
    dequeue = 1'b0;
    enqueue = 1'b0;
    rs_index = 1'b0;
    
    tail_next = (tail == FIFO_LEN) ? 0 :(tail + 1);
    head_next = (head == FIFO_LEN) ? 0 :(head + 1);

    full = (tail_next == head);
    empty = head==tail;

    cs = instr_fifo[head].chip_select;

    if(!empty && cs != 0 && cs<=NUM_RS) begin
        rs_index = instr_fifo[head].chip_select - 1;
        dequeue = !rs_empty[rs_index] && !ROB_full;
        dequeue_rs_fifo[rs_index] = dequeue;
    end

    enqueue = (!full || dequeue) && (decoded_instr.chip_select != 0);
    
end

always_ff @(posedge clk) begin
    if(!reset_n) begin
        alloc_instr_q <= 'd0;
        rs_slot_id_q <= 'd0;
        head <= 'd0;
        tail <= 'd0;
    end

    else begin // working logic

        if(dequeue) begin
            alloc_instr_q <= instr_fifo[head];
            rs_slot_id_q <= next_rs_slot[rs_index];
            head <= head_next;
        end
        else begin// default value
            alloc_instr_q <= 'd0;
            rs_slot_id_q <= 'd0;
        end

        if(enqueue) begin
            instr_fifo[tail] <= decoded_instr;
            tail <= tail_next;
        end

    end
end

assign instr_valid = (alloc_instr_q.chip_select != 0);

assign alloc_instr_RAT.valid = instr_valid;
assign alloc_instr_RAT.operation = alloc_instr_q.operation;
assign alloc_instr_RAT.src1_address = alloc_instr_q.src1_address;
assign alloc_instr_RAT.src2_address = alloc_instr_q.src2_address;
assign alloc_instr_RAT.chip_select = alloc_instr_q.chip_select;
assign alloc_instr_RAT.RS_slot_ID = rs_slot_id_q;

assign alloc_instr_ROB.valid = instr_valid;
assign alloc_instr_ROB.dest_address = alloc_instr_q.dest_address;
assign alloc_instr_ROB.branch = alloc_instr_q.branch;
assign alloc_instr_ROB.target_pc = alloc_instr_q.target_pc;

assign alloc_instr_Reg.valid = instr_valid;
assign alloc_instr_Reg.src1_address = alloc_instr_q.src1_address;
assign alloc_instr_Reg.src2_address = alloc_instr_q.src2_address;
assign alloc_instr_Reg.read_src2 = alloc_instr_q.read_src2;

assign queue_ready = (!full || dequeue);

endmodule