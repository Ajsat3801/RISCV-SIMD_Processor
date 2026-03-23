/*
    instruction queue - circular FIFO that accumulates and 
    sends one instruction at a time to the ARR pipeline

    Notes:

*/

import config_pkg::*;

module instruction_queue #()(
    input logic clk,
    input logic reset_n,

    // inputs from decode
    input instr_pkg::decoded_instr_t decoded_instr,
    output queue_ready,

    // array of inputs from Reservation Stations
    // Note: 1 more than NUM RS because ALU can release 2 slots
    input logic[$clog2(RS_MAX_LEN)-1:0] rs_slot_released_id [NUMBER_OF_EX-1:0],
    input logic rs_released [NUMBER_OF_EX-1:0]

    // outputs to instruction bus
    output signal_pkg::queue_to_rob_signal_t alloc_instr_rob;
    output signal_pkg::queue_to_rat_signal_t alloc_instr_rat;
    output signal_pkg::queue_to_reg_signal_t alloc_instr_reg;

    input rob_full;

);

// RS Slot tracking buffer
// NOTE: track chip_select-1 field for each RS; CS=0 dont do anything
logic[RS_ADDR_W-1:0] next_rs_slot[NUMBER_OF_RS-2:0];
logic[NUMBER_OF_RS-1:0] rs_full, rs_empty, dequeue_rs_fifo;

// Instruction FIFO
instr_pkg::decoded_instr_t instr_fifo[INSTRUCTION_QUEUE_LEN:0]; // N+1 entry buffer
logic[INSTRUCTION_QUEUE_PTR_LEN-1:0] head, tail, head_next, tail_next;
logic full, empty, enqueue, dequeue;

// output flip flops
instr_pkg::decoded_instr_t alloc_instr_q;
logic[RS_ADDR_W-1:0] rs_slot_id_q;

logic[RS_IDX_W-1:0] rs_index;
instr_pkg::chip_select_e cs;

rs_slot_freeq_2push #(.BUFFER_SIZE(16), .T(logic[RS_ADDR_W-1:0])) alu_fifo (
    .clk(clk),
    .reset_n(reset_n),
    .push1(rs_released[0]),
    .push1_data(rs_slot_released_id[0]),
    .push2(rs_released[1]),
    .push2_data(rs_slot_released_id[1]),
    .pop(dequeue_rs_fifo[0]),
    .data_out(next_rs_slot[0]),
    .empty(rs_empty[0]),
    .full(rs_full[0]),
);


/* FIFOs to cater for future EX units

rs_slot_freeq_1push #(.BUFFER_SIZE(8), .T(logic[RS_ADDR_W-1:0])) muldiv_fifo (
    .clk(clk),
    .reset_n(reset_n),
    .push(rs_released[2]),
    .push_data(rs_slot_released_id[2]),
    .pop(dequeue_rs_fifo[1]),
    .data_out(next_rs_slot[1]),
    .empty(rs_empty[1]),
    .full(rs_full[1]),
);

rs_slot_freeq_1push #(.BUFFER_SIZE(8), .T(logic[RS_ADDR_W-1:0])) lsu_fifo (
    .clk(clk),
    .reset_n(reset_n),
    .push(rs_released[3]),
    .push_data(rs_slot_released_id[3]),
    .pop(dequeue_rs_fifo[2]),
    .data_out(next_rs_slot[2]),
    .empty(rs_empty[2]),
    .full(rs_full[2]),
);
*/

// enqueue if instruction is valid
// dequeue if buffer isnt empty && rs slot available for head of buffer

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

    if(!empty && instr_fifo[head].valid ) begin
        if(cs!=0 && cs<NUMBER_OF_RS) begin
            rs_index = instr_fifo[head].chip_select - 1;
            dequeue = !rs_empty[rs_index] && !rob_full;
            dequeue_rs_fifo[rs_index] = dequeue;
        end
        else begin
            dequeue = !rob_full;
            dequeue_rs_fifo = '0;
        end
    end

    enqueue = (!full || dequeue) && decoded_instr.valid;
    
end

always_ff @(posedge clk) begin
    if(!reset_n) begin
        alloc_instr_q <= '0;
        rs_slot_id_q <= '0;
        head <= '0;
        tail <= '0;
    end

    else begin // working logic

        if(dequeue) begin
            alloc_instr_q <= instr_fifo[head];
            rs_slot_id_q <= next_rs_slot[rs_index];
            head <= head_next;
        end
        else begin// default value
            alloc_instr_q <= '0;
            rs_slot_id_q <= '0;
        end

        if(enqueue) begin
            instr_fifo[tail] <= decoded_instr;
            tail <= tail_next;
        end

    end
end

assign instr_valid = (alloc_instr_q.chip_select != 0);

assign alloc_instr_rat.valid = instr_valid;
assign alloc_instr_rat.operation = alloc_instr_q.operation;
assign alloc_instr_rat.src1_address = alloc_instr_q.src1_address;
assign alloc_instr_rat.src2_address = alloc_instr_q.src2_address;
assign alloc_instr_rat.chip_select = alloc_instr_q.chip_select;
assign alloc_instr_rat.RS_slot_ID = rs_slot_id_q;

assign alloc_instr_rob.valid = instr_valid;
assign alloc_instr_rob.write_to_reg = alloc_instr_q.write_to_reg;
assign alloc_instr_rob.dest_address = alloc_instr_q.dest_address;
assign alloc_instr_rob.src1_address = alloc_instr_q.src1_address;
assign alloc_instr_rob.src2_address = alloc_instr_q.src2_address;
assign alloc_instr_rob.imm = alloc_instr_q.imm;
assign alloc_instr_rob.extend = alloc_instr_q.extend;
assign alloc_instr_rob.precalc = alloc_instr_q.precalc;
assign alloc_instr_rob.branch_taken = alloc_instr_q.branch_taken;
assign alloc_instr_rob_ready = alloc_instr_q.valid && (alloc_instr_q.chip_select == '0);

assign alloc_instr_reg.valid = instr_valid;
assign alloc_instr_reg.src1_address = alloc_instr_q.src1_address;
assign alloc_instr_reg.src2_address = alloc_instr_q.src2_address;
assign alloc_instr_reg.read_src2 = alloc_instr_q.read_src2;

assign queue_ready = (!full || dequeue);

endmodule