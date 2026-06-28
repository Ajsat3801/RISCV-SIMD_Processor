/* ------------------------------------------------------------------------------------------------
 *                            RESERVATION STATION FOR LOAD-STORE UNIT
 * ------------------------------------------------------------------------------------------------
 *
 *  Functions / Behavior
 *  ->  Implements reservation station to schedule load/store instructions destined for load-store
 *      unit until both operands and functional unit are ready.
 *  ->  Snoops both scalar & vector CDB to mark buffered operands ready when PRF tag matches
 *      broadcast result.
 *  ->  Supports bypass if buffer is empty and LSU is ready.
 *  ->  Mask-based round-robin arbitration scheme.
 *  ->  On dispatch, selected buffer slot is cleared and dispatched entry is sent to output.
 *  ->  On reset or flush, all buffer entries, dispatch_q, and the arbitration mask are cleared.
 *
 *  Inputs
 *  ->  clk, reset_n & flush
 *  ->  rs_request_i — Allocation bus carrying the incoming RS entry.
 *  ->  sc_data_bus_i — Scalar common data bus snoop port.
 *  ->  vc_data_bus_i — Vector common data bus snoop port.
 *  ->  lsu_ready_i — Handshake from LSU indicating it can accept a new instruction.
 *
 *  Outputs
 *  ->  ls_read_request_o — Scalar LSU read request driven to PRF
 *  ->  vc_lsu_rd_req_o — Vector LSU read request driven to PRF
 *  ->  released_rs_slot_id_o — Slot ID of the entry dispatched this cycle.
 *  ->  rs_slot_released_o — Signal to indicate that an RS slot has been freed
 *
 *  Notes
 *  ->  On a bypass cycle no buffer slot is consumed, but outputs are treated similar to when
 *      a slot has been released
 *  ->  Both scalar & vector read requests are valid after dispatch; The respective PRFs 
 *      process the data and sends them to the LSU. LSU handles the data and gating.
 *
 * ------------------------------------------------------------------------------------------------
 */

module rs_load_store (
    input clk_i,
    input reset_ni,
    input flush_i,

    if_alloc_bus.rs rs_request_i,

    if_data_bus.snoop sc_data_bus_i,
    if_data_bus.snoop vc_data_bus_i,
    
    output packet_pkg::read_request_t ls_read_request_o,
    output packet_pkg::vc_lsu_read_request_t vc_lsu_rd_req_o,
    
    input  logic lsu_ready_i,

    output signal_pkg::rs_slot_id_t released_rs_slot_id_o,
    output logic rs_slot_released_o
);

    packet_pkg::rs_entry_t buffer[SINGLE_SLOT_RS_LEN-1:0];
    logic instr_valid, dispatch, bypass;
    
    logic [SINGLE_SLOT_RS_LEN-1:0] eligible, mask, mask_next, winner;
    logic [SINGLE_SLOT_RS_LEN-1:0] mask_upper, upper_canditates, lower_canditates, winner_upper, winner_lower;
    signal_pkg::rs_slot_id_t choice;


    packet_pkg::rs_entry_t dispatch_q;


    always_comb begin

        mask_upper       = '0;
        upper_canditates = '0;
        lower_canditates = '0;
        winner_upper     = '0;
        winner_lower     = '0;
        winner           = '0;

        instr_valid =   rs_request_i.valid && (
                        rs_request_i.chip_select == signal_pkg::CS_VLSU ||
                        rs_request_i.chip_select == signal_pkg::CS_SLSU );

        for (int i=0; i<SINGLE_SLOT_RS_LEN; i++) begin
            eligible[i] =   buffer[i].occupied && 
                            buffer[i].operand_a_ready && 
                            buffer[i].operand_b_ready;
        end
        
        bypass =    instr_valid && 
                    rs_request_i.rs_entry.operand_a_ready &&
                    rs_request_i.rs_entry.operand_b_ready && 
                    !(|eligible) &&
                    lsu_ready_i;

        dispatch =  |eligible && lsu_ready_i;

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

    always_comb begin

        ls_read_request_o.valid     = dispatch_q.occupied;
        ls_read_request_o.prf_tag   = dispatch_q.prf_tag;
        ls_read_request_o.rob_id    = dispatch_q.rob_id;
        ls_read_request_o.operation = dispatch_q.operation;

        ls_read_request_o.operand_a_tag = dispatch_q.operand_a_tag;
        ls_read_request_o.operand_b_tag = dispatch_q.operand_b_tag;

        ls_read_request_o.imm = dispatch_q.imm;
        ls_read_request_o.read_src2 = dispatch_q.read_src2;

        ls_read_request_o.a_is_vector = dispatch_q.a_is_vector;
        ls_read_request_o.b_is_vector = dispatch_q.b_is_vector;
        
        vc_lsu_rd_req_o.store_data_tag = dispatch_q.operand_b_tag;
        
        vc_lsu_rd_req_o.a_is_vector  = dispatch_q.a_is_vector;
        vc_lsu_rd_req_o.b_is_vector  = dispatch_q.b_is_vector;

    end

    always_ff @(posedge clk_i) begin
        
        if (!reset_ni || flush_i) begin
            for (int i=0; i<SINGLE_SLOT_RS_LEN; i++) buffer[i] <= '0;

            released_rs_slot_id_o <= '0;
            dispatch_q <= '0;
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
                        if (
                            !buffer[i].operand_b_ready &&
                            !buffer[i].b_is_vector &&
                            (sc_data_bus_i.prf_tag == buffer[i].operand_b_tag)
                        ) begin
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
                dispatch_q.occupied  <= rs_request_i.rs_entry.occupied;
                dispatch_q.prf_tag   <= rs_request_i.rs_entry.prf_tag;
                dispatch_q.rob_id    <= rs_request_i.rs_entry.rob_id;

                dispatch_q.operation   <= rs_request_i.rs_entry.operation;

                dispatch_q.operand_a_tag   <= rs_request_i.rs_entry.operand_a_tag;
                dispatch_q.operand_b_tag   <= rs_request_i.rs_entry.operand_b_tag;

                dispatch_q.imm <= rs_request_i.rs_entry.imm;
                dispatch_q.read_src2 <= rs_request_i.rs_entry.read_src2;

                dispatch_q.a_is_vector <= rs_request_i.rs_entry.a_is_vector;
                dispatch_q.b_is_vector <= rs_request_i.rs_entry.b_is_vector;

                dispatch_q.operand_a_ready <= rs_request_i.rs_entry.operand_a_ready;
                dispatch_q.operand_b_ready <= rs_request_i.rs_entry.operand_b_ready;
            end
            
            else if(dispatch) begin
                // send slice of ROB entry to output, removing the tags and ready
                dispatch_q.occupied  <= buffer[choice].occupied;
                dispatch_q.prf_tag   <= buffer[choice].prf_tag;
                dispatch_q.rob_id    <= buffer[choice].rob_id;

                dispatch_q.operation   <= buffer[choice].operation;

                dispatch_q.operand_a_tag   <= buffer[choice].operand_a_tag;
                dispatch_q.operand_b_tag   <= buffer[choice].operand_b_tag;

                dispatch_q.imm <= buffer[choice].imm;
                dispatch_q.read_src2 <= buffer[choice].read_src2;

                dispatch_q.a_is_vector <= buffer[choice].a_is_vector;
                dispatch_q.b_is_vector <= buffer[choice].b_is_vector;

                dispatch_q.operand_a_ready <= buffer[choice].operand_a_ready;
                dispatch_q.operand_b_ready <= buffer[choice].operand_b_ready;
                
                // clearing buffer entry and sending released value
                buffer[choice] <= '0;
            end
            else dispatch_q <= '0;
            
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
                                                                    (sc_data_bus_i.valid &&
                                                                    sc_data_bus_i.prf_tag == rs_request_i.rs_entry.operand_a_tag);
                buffer[rs_request_i.rs_slot_id].operand_b_ready <=  rs_request_i.rs_entry.operand_b_ready ||
                                                                    (sc_data_bus_i.valid &&
                                                                    sc_data_bus_i.prf_tag == rs_request_i.rs_entry.operand_b_tag);
            
            end
        end
    end

    assign rs_slot_released_o = dispatch_q.occupied;

endmodule