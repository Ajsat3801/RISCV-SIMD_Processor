//import config_pkg::*;

module sc_rs_1issue #(
    parameter instr_pkg::chip_select_e CHIP_SELECT = instr_pkg::CS_SALU
)(
    input logic clk_i,
    input logic reset_ni,
    input logic flush_i,
    
    // connection with operation bus 
    operand_bus_if.rs dispatched_instr_i,

    // connection with common data bus
    data_bus_if.snoop s_data_bus_i,

    // connection with instruction queue
    output instr_pkg::rs_slot_id_t released_rs_slot_id_o,
    output logic rs_slot_released_o,

    // output to execution unit
    input ex_ready_i,
    output signal_pkg::sc_ex_input_signal_t dispatch_o
);

    storage_pkg::sc_rs_entry_t buffer[SINGLE_SLOT_RS_LEN-1:0];

    logic dispatch, instr_valid, any_eligible, bypass;
    instr_pkg::rs_slot_id_t choice, choice_idx, choice_next;
    logic [SINGLE_SLOT_RS_LEN-1:0]  eligible, snoop, operands_ready, occupied;

    always_comb begin
        dispatch    = 1'b0;
        choice_idx  = choice;
        instr_valid = dispatched_instr_i.rs_entry.occupied && dispatched_instr_i.chip_select == CHIP_SELECT;
        
        for (int i=0;i<SINGLE_SLOT_RS_LEN;i++) begin

            occupied[i] = buffer[i].occupied;
            operands_ready[i] = buffer[i].operand_a_ready && buffer[i].operand_b_ready;

        end

        snoop = occupied & ~operands_ready;
        eligible = occupied & operands_ready;
        any_eligible = | eligible;

        if (any_eligible) begin
            for (int i=choice; i<SINGLE_SLOT_RS_LEN; i++) begin
                if (eligible[i]) begin
                    choice_idx = i;
                    dispatch   = 1'b1;
                end
            end

            if (!dispatch) begin
                for (int i=0; i<choice; i++) begin
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

            if (bypass) choice_idx = dispatched_instr_i.rs_slot;
        end

        choice_next = choice_idx + (any_eligible || bypass);
    end

    always_ff @(posedge clk_i) begin
        
        if (!reset_ni || flush_i) begin
            for (int i=0; i<SINGLE_SLOT_RS_LEN; i++) buffer[i] <= '0;

            released_rs_slot_id_o <= '0;
            dispatch_o <= '0;
        end
        
        else begin

            // snoop data from CDB and update if needed
            if (s_data_bus_i.valid) begin
                for (int i=0; i<SINGLE_SLOT_RS_LEN; i++) begin
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
                dispatch_o.valid     <= dispatched_instr_i.rs_entry.occupied;
                dispatch_o.prf_tag   <= dispatched_instr_i.rs_entry.prf_tag;
                dispatch_o.rob_id    <= dispatched_instr_i.rs_entry.rob_id;
                dispatch_o.operand_a <= dispatched_instr_i.rs_entry.operand_a;
                dispatch_o.operand_b <= dispatched_instr_i.rs_entry.operand_b;
                dispatch_o.operation <= dispatched_instr_i.rs_entry.operation;
            end
            
            else if(dispatch) begin // queue not empty
                // send slice of ROB entry to output, removing the tags and ready
                dispatch_o.valid     <= buffer[choice_idx].occupied;
                dispatch_o.prf_tag   <= buffer[choice_idx].prf_tag;
                dispatch_o.rob_id    <= buffer[choice_idx].rob_id;
                dispatch_o.operand_a <= buffer[choice_idx].operand_a;
                dispatch_o.operand_b <= buffer[choice_idx].operand_b;
                dispatch_o.operation <= buffer[choice_idx].operation;
                
                // clearing buffer entry and sending released value
                buffer[choice_idx] <= '0;
            end
            else dispatch_o <= '0;
            
            released_rs_slot_id_o <= choice_idx;
            choice <= choice_next;

            // instruction issued
            if (instr_valid && !bypass) buffer[dispatched_instr_i.rs_slot] <= dispatched_instr_i.rs_entry;

        end
    end

    assign rs_slot_released_o    = dispatch_o.valid;

endmodule