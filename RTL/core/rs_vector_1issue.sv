/* ------------------------------------------------------------------------------------------------
 *                              VECTOR SINGLE ISSUE RESERVATION STATION
 * ------------------------------------------------------------------------------------------------
 *
 *   Functions/Behavior
 *  ->  Reservation station for vector operations.
 *  ->  Logic & functionality similar to load-store reservation station with slight changes (refer
 *      to rs_load_store.sv for details)
 *
 *  Inputs:
 *  ->  clk, reset_n & flush
 *  ->  rs_request_i — Instruction to be allocated.
 *  ->  sc_data_bus_i — Snoop scalar CDB
 *  ->  vc_data_bus_i — Snoop vector CDB 
 *  ->  vc_ex_ready_i — Ready signal from vector execution unit
 *
 *  Outputs:
 *  ->  vc_read_request_o — Read request sent to the vector execution unit. 
 *  ->  sc_read_request_tag_o — The PRF tag for the scalar source operand A.
 *  ->  released_rs_slot_id_o — The RS slot ID of the instruction dispatched
 *  ->  rs_slot_released_o — signal indicating slot has been released
 *
 * ------------------------------------------------------------------------------------------------
 */


module rs_vector_1issue #(
    parameter signal_pkg::chip_select_e CHIP_SELECT = signal_pkg::CS_VALU
)(
    input clk_i,
    input reset_ni,
    input flush_i,

    if_alloc_bus.rs rs_request_i,

    if_data_bus.snoop sc_data_bus_i,
    if_data_bus.snoop vc_data_bus_i,
    
    input logic vc_ex_ready_i,
    output packet_pkg::read_request_t vc_read_request_o,
    output signal_pkg::prf_tag_t sc_read_request_tag_o,

    output signal_pkg::rs_slot_id_t released_rs_slot_id_o,
    output logic rs_slot_released_o
);

    packet_pkg::rs_entry_t buffer[SINGLE_SLOT_RS_LEN-1:0];
    logic instr_valid, dispatch, bypass;
    
    logic [SINGLE_SLOT_RS_LEN-1:0] eligible, mask, mask_next, winner;
    logic [SINGLE_SLOT_RS_LEN-1:0] mask_upper, upper_canditates, lower_canditates, winner_upper, winner_lower;
    signal_pkg::rs_slot_id_t choice;

    always_comb begin

        mask_upper       = '0;
        upper_canditates = '0;
        lower_canditates = '0;
        winner_upper     = '0;
        winner_lower     = '0;
        winner           = '0;

        instr_valid = rs_request_i.valid && rs_request_i.chip_select == CHIP_SELECT;

        for (int i=0; i<SINGLE_SLOT_RS_LEN; i++) begin
            eligible[i] =   buffer[i].occupied && 
                            buffer[i].operand_a_ready && 
                            buffer[i].operand_b_ready;
        end
        
        bypass =    instr_valid && 
                    rs_request_i.rs_entry.operand_a_ready &&
                    rs_request_i.rs_entry.operand_b_ready && 
                    !(|eligible) &&
                    vc_ex_ready_i;

        dispatch =  |eligible && vc_ex_ready_i;

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
            choice = (bypass) ? rs_request_i.rs_slot_id : '0;
        end
    end 

    always_ff @(posedge clk_i) begin
        
        if (!reset_ni || flush_i) begin
            for (int i=0; i<SINGLE_SLOT_RS_LEN; i++) buffer[i] <= '0;

            released_rs_slot_id_o <= '0;
            vc_read_request_o <= '0;
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
                vc_read_request_o.valid     <= rs_request_i.rs_entry.occupied;
                vc_read_request_o.prf_tag   <= rs_request_i.rs_entry.prf_tag;
                vc_read_request_o.rob_id    <= rs_request_i.rs_entry.rob_id;
                vc_read_request_o.operation <= rs_request_i.rs_entry.operation;

                vc_read_request_o.a_is_vector <= rs_request_i.rs_entry.a_is_vector;
                vc_read_request_o.b_is_vector <= rs_request_i.rs_entry.b_is_vector;
                vc_read_request_o.operand_a_tag <= rs_request_i.rs_entry.operand_a_tag;
                vc_read_request_o.operand_b_tag <= rs_request_i.rs_entry.operand_b_tag;

                sc_read_request_tag_o <= rs_request_i.rs_entry.operand_a_tag;
            end
            
            else if(dispatch) begin
                // send slice of ROB entry to output, removing the tags and ready
                vc_read_request_o.valid     <= buffer[choice].occupied;
                vc_read_request_o.prf_tag   <= buffer[choice].prf_tag;
                vc_read_request_o.rob_id    <= buffer[choice].rob_id;
                vc_read_request_o.operation <= buffer[choice].operation;
                vc_read_request_o.a_is_vector <= buffer[choice].a_is_vector;
                vc_read_request_o.b_is_vector <= buffer[choice].b_is_vector;
                vc_read_request_o.operand_a_tag <= buffer[choice].operand_a_tag;
                vc_read_request_o.operand_b_tag <= buffer[choice].operand_b_tag;

                sc_read_request_tag_o <= buffer[choice].operand_a_tag;
                
                // clearing buffer entry and sending released value
                buffer[choice] <= '0;
            end
            else begin
                vc_read_request_o <= '0;
                sc_read_request_tag_o <= '0;
            end
            
            released_rs_slot_id_o <= choice;
            mask <= mask_next;

            // instruction added to RS
            if (instr_valid && !bypass) begin
                buffer[rs_request_i.rs_slot_id].occupied <= rs_request_i.rs_entry.occupied;
                buffer[rs_request_i.rs_slot_id].prf_tag <= rs_request_i.rs_entry.prf_tag;
                buffer[rs_request_i.rs_slot_id].rob_id <= rs_request_i.rs_entry.rob_id;
                buffer[rs_request_i.rs_slot_id].operation <= rs_request_i.rs_entry.operation;
                
                buffer[rs_request_i.rs_slot_id].operand_a_tag <= rs_request_i.rs_entry.operand_a_tag;
                buffer[rs_request_i.rs_slot_id].operand_b_tag <= rs_request_i.rs_entry.operand_b_tag;
                buffer[rs_request_i.rs_slot_id].imm <= rs_request_i.rs_entry.imm;
                buffer[rs_request_i.rs_slot_id].read_src2 <= rs_request_i.rs_entry.read_src2;
                buffer[rs_request_i.rs_slot_id].a_is_vector <= rs_request_i.rs_entry.a_is_vector;
                buffer[rs_request_i.rs_slot_id].b_is_vector <= rs_request_i.rs_entry.b_is_vector;
                buffer[rs_request_i.rs_slot_id].operand_a_ready <=  rs_request_i.rs_entry.operand_a_ready ||
                                                                    (vc_data_bus_i.valid &&
                                                                    vc_data_bus_i.prf_tag == rs_request_i.rs_entry.operand_a_tag);
                buffer[rs_request_i.rs_slot_id].operand_b_ready <=  rs_request_i.rs_entry.operand_b_ready ||
                                                                    (vc_data_bus_i.valid &&
                                                                    vc_data_bus_i.prf_tag == rs_request_i.rs_entry.operand_b_tag);
            
            end
        end
    end

    assign rs_slot_released_o = vc_read_request_o.valid;

endmodule