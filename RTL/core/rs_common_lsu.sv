
module rs_common_lsu (
    input clk_i,
    input reset_ni,
    input flush_i,

    if_scalar_request_bus.rs sc_rs_request_i,
    if_vector_request_bus.rs vc_rs_request_i,

    if_data_bus.snoop sc_data_bus_i,
    if_data_bus.snoop vc_data_bus_i,
    
    output signal_pkg::sc_ex_input_signal_t  sc_ex_request_o,
    output signal_pkg::vc_dispatched_instr_t vc_read_request_o,
    
    input  logic vc_ex_ready_i,

    output instr_pkg::rs_slot_id_t released_rs_slot_id_o,
    output logic rs_slot_released_o
);

    storage_pkg::lsu_rs_entry_t buffer[SINGLE_SLOT_RS_LEN-1:0];
    logic instr_valid, dispatch, bypass;
    
    logic [SINGLE_SLOT_RS_LEN-1:0] eligible, mask, mask_next, winner;
    logic [SINGLE_SLOT_RS_LEN-1:0] mask_upper, upper_canditates, lower_canditates, winner_upper, winner_lower;
    instr_pkg::rs_slot_id_t choice;


    storage_pkg::lsu_rs_entry_t built_entry, dispatch_q;

    typedef enum logic {VECTOR_DISPATCHED, NO_DISPATCH} dispatch_state_e;
    dispatch_state_e dispatch_state;


    always_comb begin

        built_entry.occupied = sc_rs_request_i.rs_entry.occupied && vc_rs_request_i.valid;
        built_entry.prf_tag  = vc_rs_request_i.prf_tag;
        built_entry.rob_id   = vc_rs_request_i.rob_id;
        
        built_entry.operation   = vc_rs_request_i.operation;
        built_entry.a_is_vector = vc_rs_request_i.a_is_vector;
        built_entry.b_is_vector = vc_rs_request_i.b_is_vector;

        if (!built_entry.a_is_vector) begin
            built_entry.operand_a       = sc_rs_request_i.rs_entry.operand_a;
            built_entry.operand_a_tag   = sc_rs_request_i.rs_entry.operand_a_tag;
            built_entry.operand_a_ready = sc_rs_request_i.rs_entry.operand_a_ready;
        end
        else begin
            built_entry.operand_a       = '0;
            built_entry.operand_a_tag   = vc_rs_request_i.operand_a_tag;
            built_entry.operand_a_ready = vc_rs_request_i.operand_a_ready;
        end
        
        if(!built_entry.b_is_vector) begin
            built_entry.operand_b       = sc_rs_request_i.rs_entry.operand_b;
            built_entry.operand_b_tag   = sc_rs_request_i.rs_entry.operand_b_tag;
            built_entry.operand_b_ready = sc_rs_request_i.rs_entry.operand_b_ready;
        end
        else begin
            built_entry.operand_b       = '0;
            built_entry.operand_b_tag   = vc_rs_request_i.operand_b_tag;
            built_entry.operand_b_ready = vc_rs_request_i.operand_b_ready;
        end

        mask_upper       = '0;
        upper_canditates = '0;
        lower_canditates = '0;
        winner_upper     = '0;
        winner_lower     = '0;
        winner           = '0;

        instr_valid =   built_entry.occupied && (
                        vc_rs_request_i.chip_select == instr_pkg::CS_VLSU ||
                        sc_rs_request_i.chip_select == instr_pkg::CS_SLSU );

        for (int i=0; i<SINGLE_SLOT_RS_LEN; i++) begin
            eligible[i] =   buffer[i].occupied && 
                            buffer[i].operand_a_ready && 
                            buffer[i].operand_b_ready;
        end
        
        bypass =    instr_valid && 
                    built_entry.operand_a_ready &&
                    built_entry.operand_b_ready && 
                    !(|eligible) &&
                    (dispatch_state == NO_DISPATCH) &&
                    vc_ex_ready_i;

        dispatch =  |eligible && (dispatch_state == NO_DISPATCH) && vc_ex_ready_i;

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
            choice = (bypass) ? vc_rs_request_i.rs_slot : '0;
        end
    end 

    always_comb begin
        if(dispatch_q.prf_tag.vector) begin
            vc_read_request_o.valid     = dispatch_q.occupied;
            vc_read_request_o.prf_tag   = dispatch_q.prf_tag;
            vc_read_request_o.rob_id    = dispatch_q.rob_id;
            vc_read_request_o.operand_a = dispatch_q.operand_a;
            
            vc_read_request_o.operation = dispatch_q.operation;
            vc_read_request_o.a_is_vector = dispatch_q.a_is_vector;
            vc_read_request_o.b_is_vector = dispatch_q.b_is_vector;
            vc_read_request_o.operand_a_tag = dispatch_q.operand_a_tag;
            vc_read_request_o.operand_b_tag = dispatch_q.operand_b_tag;

            sc_ex_request_o = '0;
        end
        else begin
            /* Scalar dispatch
            */
            sc_ex_request_o.valid     = dispatch_q.occupied;
            sc_ex_request_o.prf_tag   = dispatch_q.prf_tag;
            sc_ex_request_o.rob_id    = dispatch_q.rob_id;
            sc_ex_request_o.operand_a = dispatch_q.operand_a;
            sc_ex_request_o.operand_b = dispatch_q.operand_b;
            sc_ex_request_o.operation = dispatch_q.operation;

            vc_read_request_o = '0;
        end
    end

    always_ff @(posedge clk_i) begin
        
        if (!reset_ni || flush_i) begin
            for (int i=0; i<SINGLE_SLOT_RS_LEN; i++) buffer[i] <= '0;

            released_rs_slot_id_o <= '0;
            dispatch_q <= '0;
            mask <= {{SINGLE_SLOT_RS_LEN-1{1'b0}},1'b1};
            dispatch_state = NO_DISPATCH;

        end
        
        else begin
            if (dispatch_state == VECTOR_DISPATCHED) dispatch_state = NO_DISPATCH;

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
                        if (
                            !buffer[i].operand_b_ready &&
                            !buffer[i].b_is_vector &&
                            (sc_data_bus_i.prf_tag == buffer[i].operand_b_tag)
                        ) begin
                            buffer[i].operand_b <= sc_data_bus_i.data;
                            buffer[i].operand_b_ready <= 1'b1;
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
                dispatch_q.occupied  <= built_entry.occupied;
                dispatch_q.prf_tag   <= built_entry.prf_tag;
                dispatch_q.rob_id    <= built_entry.rob_id;
                dispatch_q.operand_a <= built_entry.operand_a;
                dispatch_q.operand_b <= built_entry.operand_b;

                dispatch_q.operation   <= built_entry.operation;
                dispatch_q.a_is_vector <= built_entry.a_is_vector;
                dispatch_q.b_is_vector <= built_entry.b_is_vector;

                dispatch_q.operand_a_tag   <= built_entry.operand_a_tag;
                dispatch_q.operand_b_tag   <= built_entry.operand_b_tag;
                dispatch_q.operand_a_ready <= built_entry.operand_a_ready;
                dispatch_q.operand_b_ready <= built_entry.operand_b_ready;

                if(built_entry.prf_tag.vector) dispatch_state <= VECTOR_DISPATCHED;
            end
            
            else if(dispatch) begin
                // send slice of ROB entry to output, removing the tags and ready
                dispatch_q.occupied  <= buffer[choice].occupied;
                dispatch_q.prf_tag   <= buffer[choice].prf_tag;
                dispatch_q.rob_id    <= buffer[choice].rob_id;
                dispatch_q.operand_a <= buffer[choice].operand_a;
                dispatch_q.operand_b <= buffer[choice].operand_b;

                dispatch_q.operation   <= buffer[choice].operation;
                dispatch_q.a_is_vector <= buffer[choice].a_is_vector;
                dispatch_q.b_is_vector <= buffer[choice].b_is_vector;

                dispatch_q.operand_a_tag   <= buffer[choice].operand_a_tag;
                dispatch_q.operand_b_tag   <= buffer[choice].operand_b_tag;
                dispatch_q.operand_a_ready <= buffer[choice].operand_a_ready;
                dispatch_q.operand_b_ready <= buffer[choice].operand_b_ready;
                
                // clearing buffer entry and sending released value
                buffer[choice] <= '0;

                if(buffer[choice].prf_tag.vector) dispatch_state <= VECTOR_DISPATCHED;
            end
            else dispatch_q <= '0;
            
            released_rs_slot_id_o <= choice;
            mask <= mask_next;

            // instruction added to RS
            if (instr_valid && !bypass) buffer[vc_rs_request_i.rs_slot] <= built_entry;

        end
    end

    assign rs_slot_released_o = dispatch_q.occupied;

endmodule