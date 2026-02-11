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
    output queue_full,

    // outputs to instruction bus
    instruction_bus_if.Instruction_Queue alloc_instr,

    // array of inputs from Reservation Stations
    input logic[($clog2(RS_LEN)*NUM_RS)-1:0] rs_slot_released_id,
    input logic[NUM_RS-1:0] rs_released

);

localparam RS_ADDR_LEN = $clog2(RS_LEN);
localparam 

// RS Slot tracking buffer
// NOTE: track chip_select-1 field for each RS; CS=0 dont do anything
logic[RS_ADDR_LEN-1:0] next_rs_slot[RS_LEN-1:0];
logic[NUM_RS-1:0] rs_full, rs_empty;

// Instruction FIFO
decoded_instr_t instr_FIFO[FIFO_LEN:0];
logic[$clog2(FIFO_LEN)-1:0] head, tail;
logic full, empty;

// output flip flops
decoded_instr_t alloc_instr_q;
logic[RS_ADDR_LEN-1:0] rs_slot_id_q;



// intermediate logic signals
logic rs_empty_imm, rs_released_imm, instr_valid, not_empty, not_rs_empty, fifo_ready, rs_ready;
logic[2:0] dispatch_op, dispatch_rs;
logic enqueue_FIFO;
logic[NUM_RS-1] enqueue_RS_FIFO;
chip_select_e rs_select;

always_comb begin
    enqueue_RS_FIFO = rs_released;
    dispatch_op = 2'b00;
    dispatch_rs = 2'b00;

    instr_valid = decoded_instr.chip_select!= 0;
    not_empty = !empty;

    if(not_empty) begin 
        rs_select = instr_FIFO[head].chip_select - 'd1;
        rs_empty_imm =  rs_empty[rs_select];
        rs_released_imm = rs_released[rs_select];
    end
    else if(instr_valid) begin
        rs_select = decoded_instr.chip_select - 'd1;
        rs_empty_imm =  rs_empty[rs_select];
        rs_released_imm = rs_released[rs_select];
    end
    else begin
        rs_select = 'd0;
        rs_empty_imm = 1'b1;
        rs_released_imm = 1'b1;
    end

    not_rs_empty = !rs_empty_imm;

    fifo_ready = not_empty || (empty && instr_valid);
    rs_ready = not_rs_empty || (rs_empty_imm && rs_released_imm);

    dispatch_op[0] = not_empty && rs_ready;
    dispatch_op[1] = empty && instr_valid && rs_ready;
    
    dispatch_rs[0] = not_rs_empty && fifo_ready;
    dispatch_rs[1] = rs_empty_imm && rs_released_imm && fifo_ready;

    enqueue_FIFO = instr_valid && (not_empty || (empty && rs_empty_imm && !rs_released_imm));
    enqueue_RS_FIFO[rs_select] = rs_released_imm && (!rs_empty_imm || (empty && !instr_valid && rs_empty_imm));

    // enqueue: for main buffer only from instruction. 
end

genvar i;
generate
    for(1=0; i<NUM_RS; i++) begin
        circular_FIFO_fwft #(BUFFER_SIZE = NUM_RS, DATA_SIZE = RS_ADDR_LEN) rs_fifo (
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


always_ff @(posedge clk) begin
    if(!reset_n) begin
        /*
            All RS buffers should have 0 to RS_LEN-1;
            Full = 0;
            empty = 1;
            heads = 0;
            tails = 0;
        */
    end

    else begin // working logic

    unique case(1'b1)  // deterime instruction
        dispatch_op[0]: begin
            alloc_instr_q <= instr_FIFO[head];
            // dequeue FIFO logic comes here
        end
        dispatch_op[1] alloc_instr_q <= decoded_instr;
        default: alloc_instr_q.chip_select <= 0;

    endcase

    unique case(1'b1)
        dispatch_rs[0]: begin // send the head of the RS FIFO
            rs_slot_id_q <= RS_slot_FIFO[rs_select][RS_head[rs_select]];
            // dequeue RS logic
        end
        dispatch_rs[1]: rs_slot_id_q <= rs_slot_released_id;
        default rs_slot_id_q <= 0;
    endcase

    if(enqueue_FIFO) begin 
        // add logic for enqueue here
    end

    if(enqueue_RS_FIFO) begin
        // add logic for dequeue here
    end
        

    end
end

assign alloc_instr.alloc_instr <= alloc_instr_q;
assign alloc_instr.RS_slot_ID <= rs_slot_id_q;
assign valid = (alloc_instr_q.chip_select != 0);
assign queue_full = full;

endmodule