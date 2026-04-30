//import config_pkg::*;

module rs_scalar_1issue #(
    parameter instr_pkg::chip_select_e CHIP_SELECT = instr_pkg::CS_SALU
)(
    input  logic clk_i,
    input  logic reset_ni,
    input  logic flush_i,
     
    if_scalar_request_bus.rs sc_rs_request_i,
    if_data_bus.snoop sc_data_bus_i,

    input  logic sc_ex_ready_i,
    output packet_pkg::sc_ex_request_t sc_ex_request_o,

    output instr_pkg::rs_slot_id_t released_rs_slot_id_o,
    output logic rs_slot_released_o
);

    packet_pkg::sc_rs_entry_t buffer[SINGLE_SLOT_RS_LEN-1:0];
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

        instr_valid = sc_rs_request_i.rs_entry.occupied && sc_rs_request_i.chip_select == CHIP_SELECT;

        for (int i=0; i<SINGLE_SLOT_RS_LEN; i++) begin
            eligible[i] =   buffer[i].occupied && 
                            buffer[i].operand_a_ready && 
                            buffer[i].operand_b_ready;
        end
        
        bypass =    instr_valid && 
                    sc_rs_request_i.rs_entry.operand_a_ready &&
                    sc_rs_request_i.rs_entry.operand_b_ready && 
                    !(|eligible) &&
                    sc_ex_ready_i;

        dispatch =  |eligible && sc_ex_ready_i;

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
            choice = (bypass) ? sc_rs_request_i.rs_slot : '0;
        end
    end 

    always_ff @(posedge clk_i) begin
        
        if (!reset_ni || flush_i) begin
            for (int i=0; i<SINGLE_SLOT_RS_LEN; i++) buffer[i] <= '0;

            released_rs_slot_id_o <= '0;
            sc_ex_request_o <= '0;
            mask <= {{SINGLE_SLOT_RS_LEN-1{1'b0}},1'b1};

        end
        
        else begin

            // snoop data from CDB and update if needed
            if (sc_data_bus_i.valid) begin
                for (int i=0; i<SINGLE_SLOT_RS_LEN; i++) begin
                    if (buffer[i].occupied && (sc_data_bus_i.prf_tag == buffer[i].operand_a_tag) && !buffer[i].operand_a_ready) begin 
                        buffer[i].operand_a <= sc_data_bus_i.data;
                        buffer[i].operand_a_ready <= 1'b1;
                    end

                    if (buffer[i].occupied && (sc_data_bus_i.prf_tag == buffer[i].operand_b_tag) && !buffer[i].operand_b_ready) begin
                        buffer[i].operand_b <= sc_data_bus_i.data;
                        buffer[i].operand_b_ready <= 1'b1;
                    end
                end
            end

            // dequeue instructions
            if(bypass) begin
                // send slice of RS input to output, removing the tags and ready
                sc_ex_request_o.valid     <= sc_rs_request_i.rs_entry.occupied;
                sc_ex_request_o.prf_tag   <= sc_rs_request_i.rs_entry.prf_tag;
                sc_ex_request_o.rob_id    <= sc_rs_request_i.rs_entry.rob_id;
                sc_ex_request_o.operand_a <= sc_rs_request_i.rs_entry.operand_a;
                sc_ex_request_o.operand_b <= sc_rs_request_i.rs_entry.operand_b;
                sc_ex_request_o.operation <= sc_rs_request_i.rs_entry.operation;
            end
            
            else if(dispatch) begin
                // send slice of ROB entry to output, removing the tags and ready
                sc_ex_request_o.valid     <= buffer[choice].occupied;
                sc_ex_request_o.prf_tag   <= buffer[choice].prf_tag;
                sc_ex_request_o.rob_id    <= buffer[choice].rob_id;
                sc_ex_request_o.operand_a <= buffer[choice].operand_a;
                sc_ex_request_o.operand_b <= buffer[choice].operand_b;
                sc_ex_request_o.operation <= buffer[choice].operation;
                
                // clearing buffer entry and sending released value
                buffer[choice] <= '0;
            end
            else sc_ex_request_o <= '0;
            
            released_rs_slot_id_o <= choice;
            mask <= mask_next;

            // instruction added to RS
            if (instr_valid && !bypass) buffer[sc_rs_request_i.rs_slot] <= sc_rs_request_i.rs_entry;

        end
    end

    assign rs_slot_released_o = sc_ex_request_o.valid;

endmodule