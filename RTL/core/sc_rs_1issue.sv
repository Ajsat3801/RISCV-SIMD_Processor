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
    logic instr_valid, dispatch, bypass;
    
    logic [SINGLE_SLOT_RS_LEN-1:0] eligible, mask, mask_next, winner;
    logic [SINGLE_SLOT_RS_LEN-1:0] mask_upper, upper_canditates, lower_canditates, winner_upper, winner_lower;
    instr_pkg::rs_slot_id_t choice;

    always_comb begin

        mask_upper       = '0;
        upper_canditates = '0;
        lower_canditates = '0;
        winner_upper     = '0;
        winner_lower     = '0;
        winner           = '0;

        instr_valid = dispatched_instr_i.rs_entry.occupied && dispatched_instr_i.chip_select == CHIP_SELECT;

        for (int i=0; i<SINGLE_SLOT_RS_LEN; i++) begin
            eligible[i] =   buffer[i].occupied && 
                            buffer[i].operand_a_ready && 
                            buffer[i].operand_b_ready;
        end
        
        bypass =    instr_valid && 
                    dispatched_instr_i.rs_entry.operand_a_ready &&
                    dispatched_instr_i.rs_entry.operand_b_ready && 
                    !(|eligible) &&
                    ex_ready_i;

        dispatch =  |eligible && ex_ready_i;

        if (dispatch) begin
            mask_upper[0] = mask[0];

            for (int i=1; i<SINGLE_SLOT_RS_LEN; i++) begin
                mask_upper[i] = mask_upper[i-1] | mask[i];
            end

            upper_canditates = eligible & mask_upper;
            lower_canditates = eligible & ~mask_upper;

            winner_upper = upper_canditates & (~upper_canditates + 1'b1);
            winner_lower = lower_canditates & (~lower_canditates + 1'b1);

            winner = (|upper_canditates) ? winner_upper : winner_lower;

            mask_next = {winner[SINGLE_SLOT_RS_LEN-2:0], winner[SINGLE_SLOT_RS_LEN-1]};

            choice = '0;

            for (int i=0; i<SINGLE_SLOT_RS_LEN; i++) begin
                if (winner[i]) choice = i[RS_ADDR_W-1:0];
            end
        end
        else begin
            mask_next = mask;
            choice = (bypass) ? dispatched_instr_i.rs_slot : '0;
        end
    end 

    always_ff @(posedge clk_i) begin
        
        if (!reset_ni || flush_i) begin
            for (int i=0; i<SINGLE_SLOT_RS_LEN; i++) buffer[i] <= '0;

            released_rs_slot_id_o <= '0;
            dispatch_o <= '0;
            mask <= {{SINGLE_SLOT_RS_LEN-1{1'b0}},1'b1};

        end
        
        else begin

            // snoop data from CDB and update if needed
            if (s_data_bus_i.valid) begin
                for (int i=0; i<SINGLE_SLOT_RS_LEN; i++) begin
                    if (buffer[i].occupied && (s_data_bus_i.prf_tag == buffer[i].operand_a_tag) && !buffer[i].operand_a_ready) begin 
                        buffer[i].operand_a <= s_data_bus_i.data;
                        buffer[i].operand_a_ready <= 1'b1;
                    end

                    if (buffer[i].occupied && (s_data_bus_i.prf_tag == buffer[i].operand_b_tag) && !buffer[i].operand_b_ready) begin
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
            
            else if(dispatch) begin
                // send slice of ROB entry to output, removing the tags and ready
                dispatch_o.valid     <= buffer[choice].occupied;
                dispatch_o.prf_tag   <= buffer[choice].prf_tag;
                dispatch_o.rob_id    <= buffer[choice].rob_id;
                dispatch_o.operand_a <= buffer[choice].operand_a;
                dispatch_o.operand_b <= buffer[choice].operand_b;
                dispatch_o.operation <= buffer[choice].operation;
                
                // clearing buffer entry and sending released value
                buffer[choice] <= '0;
            end
            else dispatch_o <= '0;
            
            released_rs_slot_id_o <= choice;
            mask <= mask_next;

            // instruction added to RS
            if (instr_valid && !bypass) buffer[dispatched_instr_i.rs_slot] <= dispatched_instr_i.rs_entry;

        end
    end

    assign rs_slot_released_o = dispatch_o.valid;

endmodule