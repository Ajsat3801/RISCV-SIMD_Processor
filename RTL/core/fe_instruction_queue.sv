//import config_pkg::*;

module fe_instruction_queue (

    input logic clk_i,
    input logic reset_ni,
    input logic flush_i,

    input packet_pkg::decoded_instr_t decoded_instr_i,
    input signal_pkg::rs_slot_id_t released_rs_slot_id_i [RS_DISPATCH_COUNT-1:0],
    input logic rs_slot_released_i [RS_DISPATCH_COUNT-1:0],
    
    input logic rob_full_i,
    input logic sc_arr_full_i,
    input logic vc_arr_full_i,

    if_dispatch_bus.queue dispatched_instr_o,
    output queue_ready_o
);

/* INSTRUCTION QUEUE
 * Functions 
 *   -> Maintains queue of instructions that are ready to dispatch
 *   -> Keeps a FIFO of available slots of each reservation station
 *   -> Enqueue if instruction is valid
 *   -> 3 conditions for dequeue
 *      1) FIFO is not empty
 *      2) RS slot is available for the instruction at head of FIFO
 *      3) ROB is not full
 *   -> Refer to module definition of RS slot FIFO for behavior of RS slot FIFO
 * Inputs
 *   -> clk, reset_n, flush
 *   -> decoded instruction from decode
 *   -> array of RS slots released. Length of array is same as number of ex units
 *   -> array of flag bits to indicate if an RS slot is released
 *   -> signal indicating availability of ROB 
 * Outputs
 *   -> signal to decoder indicating availability of slot in FIFO
 *   -> allocated instruction and RS slot sent to instruction bus
 * Notes 
 *   -> Buffer full scenario is not handled as its assumed no valid input occurs
 *      when the buffer is full. Handled by decoder
 *   -> Number of entries in the fifo is 1 more than the buffer size for simpler logic
 *   -> If chip select is 1 we check 0th RS fifo. chip select 0 is a NOP
 * TODO Future Improvements
 *   -> Implement bypass and remove 1 cycle lag when queue is empty
 */

    // RS Slot tracking buffer
    signal_pkg::rs_slot_id_t next_rs_slot[RS_COUNT-1:0];
    logic[RS_COUNT-1:0] rs_full, rs_empty, dequeue_rs_fifo;

    // Instruction FIFO
    packet_pkg::decoded_instr_t instr_fifo[INSTRUCTION_QUEUE_LEN:0]; // N+1 entry buffer
    logic[INSTRUCTION_QUEUE_PTR_LEN-1:0] head, tail, head_next, tail_next;
    logic full, empty, enqueue, dequeue, ready;

    // output flip flops
    packet_pkg::decoded_instr_t alloc_instr_q;
    signal_pkg::rs_slot_id_t rs_slot_id_q;

    // intermediate variables
    logic[RS_IDX_W-1:0] rs_index;
    signal_pkg::chip_select_e cs;
    logic reset_wb_n;
    int i;

    lib_rs_slot_freeq_2push #(
        .BUFFER_SIZE(16),
        .T(logic[RS_ADDR_W-1:0])
    ) alu_fifo (
        .clk_i(clk_i),
        .reset_ni(reset_wb_n),
        .push1_i(rs_slot_released_i[0]),
        .push_data1_i(released_rs_slot_id_i[0]),
        .push2_i(rs_slot_released_i[1]),
        .push_data2_i(released_rs_slot_id_i[1]),
        .pop_i(dequeue_rs_fifo[0]),
        .data_o(next_rs_slot[0]),
        .empty_o(rs_empty[0]),
        .full_o(rs_full[0])
    );

    lib_rs_slot_freeq_1push #(
        .BUFFER_SIZE(8),
        .T(logic[RS_ADDR_W-1:0])
    ) muldiv_fifo (
        .clk_i(clk_i),
        .reset_ni(reset_wb_n),
        .push_i(rs_slot_released_i[2]),
        .push_data_i(released_rs_slot_id_i[2]),
        .pop_i(dequeue_rs_fifo[1]),
        .data_o(next_rs_slot[1]),
        .empty_o(rs_empty[1]),
        .full_o(rs_full[1])
    );
    
    lib_rs_slot_freeq_1push #(
        .BUFFER_SIZE(8),
        .T(logic[RS_ADDR_W-1:0])
    ) lsu_fifo (
        .clk_i(clk_i),
        .reset_ni(reset_wb_n),
        .push_i(rs_slot_released_i[3]),
        .push_data_i(released_rs_slot_id_i[3]),
        .pop_i(dequeue_rs_fifo[2]),
        .data_o(next_rs_slot[2]),
        .empty_o(rs_empty[2]),
        .full_o(rs_full[2])
    );

    lib_rs_slot_freeq_1push #(
        .BUFFER_SIZE(8),
        .T(logic[RS_ADDR_W-1:0])
    ) branch_fifo (
        .clk_i(clk_i),
        .reset_ni(reset_wb_n),
        .push_i(rs_slot_released_i[4]),
        .push_data_i(released_rs_slot_id_i[4]),
        .pop_i(dequeue_rs_fifo[3]),
        .data_o(next_rs_slot[3]),
        .empty_o(rs_empty[3]),
        .full_o(rs_full[3])
    );
    
    lib_rs_slot_freeq_1push #(
        .BUFFER_SIZE(8),
        .T(logic[RS_ADDR_W-1:0])
    ) valu_fifo (
        .clk_i(clk_i),
        .reset_ni(reset_wb_n),
        .push_i(rs_slot_released_i[5]),
        .push_data_i(released_rs_slot_id_i[5]),
        .pop_i(dequeue_rs_fifo[4]),
        .data_o(next_rs_slot[4]),
        .empty_o(rs_empty[4]),
        .full_o(rs_full[4])
    );

    always_comb begin

        dequeue_rs_fifo = '0;
        dequeue  = 1'b0;
        enqueue  = 1'b0;
        rs_index = '0;
        
        tail_next = (tail == INSTRUCTION_QUEUE_LEN) ? 0 :(tail + 1);
        head_next = (head == INSTRUCTION_QUEUE_LEN) ? 0 :(head + 1);
        tail_next_next = (tail_next == INSTRUCTION_QUEUE_LEN) ? 0 :(tail_next + 1);

        full  = (tail_next == head);
        full_next = (tail_next_next == head);
        empty = head==tail;

        cs = instr_fifo[head].chip_select;

        ready = !rob_full_i &&
                !(sc_arr_full_i && (!cs[2] || cs==3'b100)) &&
                !(vc_arr_full_i && (cs[2] && !(cs==3'b100)));

        if (!empty && instr_fifo[head].valid ) begin
            if (cs != 0 && cs != 3'b110) begin
                rs_index = instr_fifo[head].chip_select - 1'b1;
                if (cs==3'b111) rs_index = 3'b010;
                dequeue  = !rs_empty[rs_index] && ready;
                dequeue_rs_fifo[rs_index] = dequeue;
            end
            else begin
                dequeue = ready;
                dequeue_rs_fifo = '0;
            end
        end

        enqueue    = (!full || dequeue) && decoded_instr_i.valid;
        reset_wb_n = (reset_ni && !flush_i) ;
        
    end

    always_ff @(posedge clk_i) begin
        if (!reset_ni || flush_i) begin

            for (i=0; i<INSTRUCTION_QUEUE_LEN; i++) instr_fifo[i] = '0;

            alloc_instr_q <= '0;
            rs_slot_id_q  <= '0;
            head <= '0;
            tail <= '0;
        end

        else begin
            if (dequeue) begin
                alloc_instr_q <= instr_fifo[head];
                rs_slot_id_q  <= next_rs_slot[rs_index];
                head <= head_next;
            end
            else begin 
                alloc_instr_q <= '0;
                rs_slot_id_q  <= '0;
            end
            if (enqueue) begin
                instr_fifo[tail] <= decoded_instr_i;
                tail <= tail_next;
            end
        end
    end

    assign dispatched_instr_o.valid = alloc_instr_q.valid;
    assign dispatched_instr_o.instr = alloc_instr_q;
    assign dispatched_instr_o.rs_slot_id = rs_slot_id_q;

    assign queue_ready_o = dequeue || !(full || full_next);

endmodule