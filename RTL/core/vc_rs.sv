
module vc_rs #(
    parameter instr_pkg::chip_select_e CHIP_SELECT = instr_pkg::CS_VALU
)(
    input clk_i,
    input reset_ni,
    input flush_i,

    operand_bus_if.rs sc_operand_bus,
    dispatch_bus_if.rs vc_dispatch_bus,

    data_bus_if.snoop sc_data_bus_i,
    data_bus_if.snoop vc_data_bus_i,

    output signal_pkg::vc_dispatched_instr_t dispatch_o,

    output instr_pkg::rs_slot_id_t released_rs_slot_id_o,
    output logic rs_slot_released_o,

    input logic ex_ready_i
);

    storage_pkg::vc_rs_entry_t buffer[SINGLE_SLOT_RS_LEN-1:0];
    logic instr_valid, dispatch, bypass;
    
    logic [SINGLE_SLOT_RS_LEN-1:0] eligible, mask, mask_next, winner;
    logic [SINGLE_SLOT_RS_LEN-1:0] mask_upper, upper_canditates, lower_canditates, winner_upper, winner_lower;
    instr_pkg::rs_slot_id_t choice;

    storage_pkg::vc_rs_entry_t built_entry;

    always_comb begin

        built_entry.occupied = sc_operand_bus.rs_entry.occupied && vc_dispatch_bus.valid;
        built_entry.prf_tag  = vc_dispatch_bus.prf_tag;
        built_entry.rob_id   = vc_dispatch_bus.rob_id;
        
        built_entry.operation   = vc_dispatch_bus.operation;
        built_entry.a_is_vector = vc_dispatch_bus.a_is_vector;
        built_entry.b_is_vector = vc_dispatch_bus.b_is_vector;

        if (!built_entry.a_is_vector) begin
            built_entry.operand_a       = sc_operand_bus.rs_entry.operand_a;
            built_entry.operand_a_tag   = sc_operand_bus.rs_entry.operand_a_tag;
            built_entry.operand_a_ready = sc_operand_bus.rs_entry.operand_a_ready;
        end
        else begin
            built_entry.operand_a       = '0;
            built_entry.operand_a_tag   = vc_dispatch_bus.operand_a_tag;
            built_entry.operand_a_ready = vc_dispatch_bus.operand_a_ready;
        end
        
        built_entry.operand_b_tag = vc_dispatch_bus.operand_b_tag;
        built_entry.operand_b_ready = vc_dispatch_bus.operand_b_ready;

        mask_upper       = '0;
        upper_canditates = '0;
        lower_canditates = '0;
        winner_upper     = '0;
        winner_lower     = '0;
        winner           = '0;

        instr_valid = built_entry.occupied && vc_dispatch_bus.chip_select == CHIP_SELECT;

        for (int i=0; i<SINGLE_SLOT_RS_LEN; i++) begin
            eligible[i] =   buffer[i].occupied && 
                            buffer[i].operand_a_ready && 
                            buffer[i].operand_b_ready;
        end
        
        bypass =    instr_valid && 
                    built_entry.operand_a_ready &&
                    built_entry.operand_b_ready && 
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
            choice = (bypass) ? vc_dispatch_bus.rs_slot : '0;
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

            // snoop data from scalar CDB and update if needed
            if (sc_data_bus_i.valid) begin
                for (int i=0; i<SINGLE_SLOT_RS_LEN; i++) begin
                    if ( buffer[i].occupied) begin
                        if ( 
                            !buffer[i].operand_a_ready && 
                            !buffer[i].a_is_vector && 
                            (sc_data_bus_i.prf_tag == buffer[i].operand_a_tag)
                        ) begin 
                            buffer[i].operand_a <= sc_data_bus_i.data;
                            buffer[i].operand_a_ready <= 1'b1;
                        end
                    end
                end
            end

            // snoop data from vector CDB
            if (vc_data_bus_i.valid) begin
                for (int i=0; i<SINGLE_SLOT_RS_LEN; i++) begin
                    if ( buffer[i].occupied) begin
                        if ( 
                            !buffer[i].operand_a_ready && 
                            buffer[i].a_is_vector && 
                            (vc_data_bus_i.prf_tag == buffer[i].operand_a_tag)
                        ) begin 
                            buffer[i].operand_a_ready <= 1'b1;
                        end

                        if(
                            !buffer[i].operand_b_ready &&
                            buffer[i].b_is_vector && 
                            (vc_data_bus_i.prf_tag == buffer[i].operand_b_tag)
                        ) begin
                            buffer[i].operand_b_ready <= 1'b1;
                        end
                    end
                end
            end

            // dequeue instructions
            if(bypass) begin
                // send slice of RS input to output, removing the tags and ready
                dispatch_o.valid     <= built_entry.occupied;
                dispatch_o.prf_tag   <= built_entry.prf_tag;
                dispatch_o.rob_id    <= built_entry.rob_id;
                dispatch_o.operand_a <= built_entry.operand_a;
                dispatch_o.operation <= built_entry.operation;

                dispatch_o.a_is_vector <= built_entry.a_is_vector;
                dispatch_o.b_is_vector <= built_entry.b_is_vector;
                dispatch_o.operand_a_tag <= built_entry.operand_a_tag;
                dispatch_o.operand_b_tag <= built_entry.operand_b_tag;
            end
            
            else if(dispatch) begin
                // send slice of ROB entry to output, removing the tags and ready
                dispatch_o.valid     <= buffer[choice].occupied;
                dispatch_o.prf_tag   <= buffer[choice].prf_tag;
                dispatch_o.rob_id    <= buffer[choice].rob_id;
                dispatch_o.operand_a <= buffer[choice].operand_a;
                dispatch_o.operation <= buffer[choice].operation;
                dispatch_o.a_is_vector <= buffer[choice].a_is_vector;
                dispatch_o.b_is_vector <= buffer[choice].b_is_vector;
                dispatch_o.operand_a_tag <= buffer[choice].operand_a_tag;
                dispatch_o.operand_b_tag <= buffer[choice].operand_b_tag;
                
                // clearing buffer entry and sending released value
                buffer[choice] <= '0;
            end
            else dispatch_o <= '0;
            
            released_rs_slot_id_o <= choice;
            mask <= mask_next;

            // instruction added to RS
            if (instr_valid && !bypass) buffer[vc_dispatch_bus.rs_slot] <= built_entry;

        end
    end

    assign rs_slot_released_o = dispatch_o.valid;

endmodule