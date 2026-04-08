/*
    IF timing problem
    1) you can take occupied out and set as separate bitmap
*/

module res_station_single_issue #(
    parameter CHIP_SELECT = 1
    )(
    input logic clk,
    input logic reset_n,
    
    // connection with operation bus 
    operand_bus_if.rs rs_input,

    // connection with common data bus
    common_data_bus_if.snoop cdb_data,

    // connection with instruction queue
    output logic[SINGLE_SLOT_RS_IDX_W-1:0] rs_slot_released_id,
    output logic rs_slot_released,

    // output to execution unit
    input ex_ready,
    output signal_pkg::rs_to_alu_signal_t dispatched_op
);

storage_pkg::rs_entry_t buffer[SINGLE_SLOT_RS_LEN-1:0];
signal_pkg::rs_to_alu_signal_t dispatched_op_q;

logic dispatch, instr_valid, any_eligible, chosen, bypass;
logic[SINGLE_SLOT_RS_IDX_W-1:0] choice, choice_idx, choice_next;
logic[SINGLE_SLOT_RS_LEN-1:0] eligible, snoop, operands_ready, occupied;

int i;

always_comb begin
    choice_idx = chosen;
    instr_valid = rs_input.rs_entry.occupied && rs_input.chip_select == CHIP_SELECT;
    
    for(i=0;i<SINGLE_SLOT_RS_LEN;i++) begin
        occupied[i] = buffer[i].occupied;
        operands_ready[i] = buffer[i].operand_a_ready && buffer[i].operand_b_ready;
    end

    snoop = occupied & ~operands_ready;
    eligible = occupied & operands_ready;
    any_eligible = ~|eligible;

    if(any_eligible) begin
        for(i=choice; i<SINGLE_SLOT_RS_LEN; i++) begin
            if(eligible[i]) begin
                choice_idx = i;
                dispatch = 1'b1;
            end
        end
        if(!dispatch) begin
            for(i=0; i<chosen; i++) begin
                if(eligible[i]) begin
                    choice_idx = i;
                    dispatch = 1'b1;
                end
            end
        end
        bypass = 1'b0;
    end
    else begin
        dispatch = 1'b0;
        bypass = instr_valid && rs_input.rs_entry.operand_a_ready && rs_input.rs_entry.operand_b_ready && ex_ready;
        if(bypass) chosen_idx = rs_input.rs_entry.rs_slot;
    end

    chosen_next = chosen_idx + (any_eligible || bypass);
end


always_ff @(posedge clk) begin
    
    if(!reset_n) begin
        
        buffer[0] <= '0;
        for(i = 1; i<SINGLE_SLOT_RS_LEN;i++) buffer[i] <= buffer[0];

        released_id_q <= '0;
        dispatched_op_q <= '0;

    end
    else begin

        // snoop data from CDB and update if needed
        if(cdb_data.valid) begin
            for(i=0;i<SINGLE_SLOT_RS_LEN;i++) begin
                if(occupied[i] && cdb_data.rob_id == buffer[i].operand_a_tag && !buffer[i].operand_a_ready) begin 
                    buffer[i].operand_a <= cdb_data.data;
                    buffer[i].operand_a_ready <= 1'b1;
                end
                if(occupied[i] && cdb_data.rob_id == buffer[i].operand_b_tag && !buffer[i].operand_b_ready) begin
                    buffer[i].operand_b <= cdb_data.data;
                    buffer[i].operand_b_ready <= 1'b1;
                end
            end
        end

        // dequeue instructions
        if(bypass) begin
            // send slice of RS input to output, removing the tags and ready
            dispatched_op_q.valid <= rs_input.rs_entry.valid;
            dispatched_op_q.rob_id <= rs_input.rs_entry.rob_id;
            dispatched_op_q.operand_a <= rs_input.rs_entry.operand_a;
            dispatched_op_q.operand_b <= rs_input.rs_entry.operand_b;
            dispatched_op_q.operation <= rs_input.rs_entry.operation;
            dispatched_op_q.sign <= rs_input.rs_entry.sign;
        end
        
        else if(dispatch) begin // queue not empty
            // send slice of ROB entry to output, removing the tags and ready
            dispatched_op_q.valid <= buffer[chosen_idx].valid;
            dispatched_op_q.rob_id <= buffer[chosen_idx].rob_id;
            dispatched_op_q.operand_a <= buffer[chosen_idx].operand_a;
            dispatched_op_q.operand_b <= buffer[chosen_idx].operand_b;
            dispatched_op_q.operation <= buffer[chosen_idx].operation;
            dispatched_op_q.sign <= buffer[chosen_idx].sign;
            
            // clearing buffer entry and sending released value
            buffer[chosen_idx] <= '0;
        end
        else dispatched_op_q <= '0;
        
        released_id_q <= chosen_idx;
        chosen <= chosen_next;

        // instruction issued
        if(instr_valid && !bypass) buffer[rs_input.rs_slot] <= rs_input.rs_entry;

    end
end

assign dispatched_op = dispatched_op_q;
assign rs_slot_released_id = released_id_q;
assign rs_slot_released = dispatched_op_q.valid;

endmodule