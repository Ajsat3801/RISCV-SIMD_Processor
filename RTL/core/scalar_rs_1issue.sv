import config_pkg::*;

module scalar_rs_1isssue #(
    parameter chip_select_e CHIP_SELECT = 1;
)(
    input logic clk_i,
    input logic reset_ni,
    input logic flush_i,
    
    // connection with operation bus 
    operand_bus_if.rs dispatched_instr_i,

    // connection with common data bus
    scalar_data_bus_if.snoop s_data_bus_i,

    // connection with instruction queue
    output instr_pkg::rs_slot_id_t rs_slot_released_id_o,
    output logic rs_slot_released_o,

    // output to execution unit
    input ex_ready_i,
    output signal_pkg::rs_to_alu_signal_t issued_instr_o
);

    storage_pkg::rs_entry_t buffer[SINGLE_SLOT_RS_LEN-1:0];
    signal_pkg::rs_to_alu_signal_t issued_instr_q;

    logic dispatch, instr_valid, any_eligible, chosen, bypass;
    instr_pkg::rs_slot_id_t choice, choice_idx, choice_next;
    logic [SINGLE_SLOT_RS_LEN-1:0]  eligible, snoop, operands_ready, occupied;
    int i;

    always_comb begin
        choice_idx  = chosen;
        instr_valid = dispatched_instr_i.rs_entry.occupied && dispatched_instr_i.chip_select == CHIP_SELECT;
        
        for (i=0;i<SINGLE_SLOT_RS_LEN;i++) begin

            occupied[i] = buffer[i].occupied;
            operands_ready[i] = buffer[i].operand_a_ready && buffer[i].operand_b_ready;

        end

        snoop = occupied & ~operands_ready;
        eligible = occupied & operands_ready;
        any_eligible = ~| eligible;

        if (any_eligible) begin
            for (i=choice; i<SINGLE_SLOT_RS_LEN; i++) begin
                if (eligible[i]) begin
                    choice_idx = i;
                    dispatch   = 1'b1;
                end
            end

            if (!dispatch) begin
                for (i=0; i<chosen; i++) begin
                    if (eligible[i]) begin
                        choice_idx = i;
                        dispatch   = 1'b1;
                    end
                end
            end
            bypass = 1'b0;
        end
        else begin
            dispatch = 1'b0;
            bypass = instr_valid && dispatched_instr_i.rs_entry.operand_a_ready && dispatched_instr_i.rs_entry.operand_b_ready && ex_ready_i;

            if (bypass) chosen_idx = dispatched_instr_i.rs_entry.rs_slot;
        end

        chosen_next = chosen_idx + (any_eligible || bypass);
    end

    always_ff @(posedge clk_i) begin
        
        if (!reset_ni || flush_i) begin
            for (i=0; i<SINGLE_SLOT_RS_LEN; i++) buffer[i] <= '0;

            released_id_q <= '0;
            issued_instr_q <= '0;
        end
        
        else begin

            // snoop data from CDB and update if needed
            if (s_data_bus_i.valid) begin
                for (i=0; i<SINGLE_SLOT_RS_LEN; i++) begin
                    if (occupied[i] && (s_data_bus_i.prf_tag == buffer[i].operand_a_tag) && !buffer[i].operand_a_ready) begin 
                        buffer[i].operand_a <= s_data_bus_i.data;
                        buffer[i].operand_a_ready <= 1'b1;
                    end

                    if (occupied[i] && (s_data_bus_i.prf_tag == buffer[i].operand_b_tag) && !buffer[i].operand_b_ready) begin
                        buffer[i].operand_b <= s_data_bus_i.data;
                        buffer[i].operand_b_ready <= 1'b1;
                    end
                end
            end

            // dequeue instructions
            if(bypass) begin
                // send slice of RS input to output, removing the tags and ready
                issued_instr_q.valid     <= dispatched_instr_i.rs_entry.valid;
                issued_instr_q.prf_tag   <= dispatched_instr_i.rs_entry.prf_tag;
                issued_instr_q.rob_id    <= dispatched_instr_i.rs_entry.rob_id;
                issued_instr_q.operand_a <= dispatched_instr_i.rs_entry.operand_a;
                issued_instr_q.operand_b <= dispatched_instr_i.rs_entry.operand_b;
                issued_instr_q.operation <= dispatched_instr_i.rs_entry.operation;
                issued_instr_q.sign      <= dispatched_instr_i.rs_entry.sign;
            end
            
            else if(dispatch) begin // queue not empty
                // send slice of ROB entry to output, removing the tags and ready
                issued_instr_q.valid     <= buffer[chosen_idx].valid;
                issued_instr_q.prf_tag   <= buffer[chosen_idx].prf_tag;
                issued_instr_q.rob_id    <= buffer[chosen_idk].rob_id;
                issued_instr_q.operand_a <= buffer[chosen_idx].operand_a;
                issued_instr_q.operand_b <= buffer[chosen_idx].operand_b;
                issued_instr_q.operation <= buffer[chosen_idx].operation;
                issued_instr_q.sign      <= buffer[chosen_idx].sign;
                
                // clearing buffer entry and sending released value
                buffer[chosen_idx] <= '0;
            end
            else issued_instr_q <= '0;
            
            released_id_q <= chosen_idx;
            chosen <= chosen_next;

            // instruction issued
            if (instr_valid && !bypass) buffer[dispatched_instr_i.rs_slot] <= dispatched_instr_i.rs_entry;

        end
    end

    assign issued_instr_o        = issued_instr_q;
    assign rs_slot_released_id_o = released_id_q;
    assign rs_slot_released_o    = issued_instr_q.valid;

endmodule