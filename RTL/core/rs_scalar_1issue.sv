/* ------------------------------------------------------------------------------------------------
 *                                   SINGLE ISSUE RESERVATION STATION
 * ------------------------------------------------------------------------------------------------
 *
 * Functions/Behavior:
 *  ->  Implements a reservation station (RS) for scalar instructions targeting a single-issue
 *      execution unit (parameterized via CHIP_SELECT, e.g. CS_SALU).
 *  ->  Supports bypass if buffer is empty and FU is ready.
 *  ->  Mask-based round-robin arbitration scheme.
 *  ->  On dispatch, selected buffer slot is cleared and dispatched entry is sent to output.
 *  ->  On reset or flush, all buffer entries, dispatch_q, and the arbitration mask are cleared.
 *
 * Inputs:
 *  ->  clk, reset_n & flush
 *  ->  rs_request_i — Allocation bus carrying the incoming instruction entry
 *  ->  sc_data_bus_i — CDB snoop interface.
 *  ->  sc_ex_ready_i — Ready signal from downstream ex unit.
 *
 * Outputs:
 *  ->  sc_rd_req_o — Read request packet sent to the execution unit.
 *  ->  released_rs_slot_id_o — ID of the RS slot freed this cycle
 *  ->  rs_slot_released_o — Signals whether RS slot was freed or not

 *
 * Notes:
 *  ->  On a bypass cycle no buffer slot is consumed, but outputs are treated similar to when
 *      a slot has been released
 *
 * ------------------------------------------------------------------------------------------------
 */

module rs_scalar_1issue #(
    parameter signal_pkg::chip_select_e CHIP_SELECT = signal_pkg::CS_SALU
)(
    input  logic clk_i,
    input  logic reset_ni,
    input  logic flush_i,
     
    if_alloc_bus.rs rs_request_i,
    if_data_bus.snoop sc_data_bus_i,

    input  logic sc_ex_ready_i,
    output packet_pkg::read_request_t sc_rd_req_o,

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
            choice = (bypass) ? rs_request_i.rs_slot_id : '0;
        end
    end 

    always_ff @(posedge clk_i) begin
        
        if (!reset_ni || flush_i) begin
            for (int i=0; i<SINGLE_SLOT_RS_LEN; i++) buffer[i] <= '0;

            released_rs_slot_id_o <= '0;
            sc_rd_req_o <= '0;
            mask <= {{SINGLE_SLOT_RS_LEN-1{1'b0}},1'b1};

        end
        
        else begin

            // snoop data from CDB and update if needed
            if (sc_data_bus_i.valid) begin
                for (int i=0; i<SINGLE_SLOT_RS_LEN; i++) begin
                    if (buffer[i].occupied && (sc_data_bus_i.prf_tag == buffer[i].operand_a_tag) && !buffer[i].operand_a_ready) begin 
                        buffer[i].operand_a_ready <= 1'b1;
                    end

                    if (buffer[i].occupied && (sc_data_bus_i.prf_tag == buffer[i].operand_b_tag) && !buffer[i].operand_b_ready) begin
                        buffer[i].operand_b_ready <= 1'b1;
                    end
                end
            end

            // dequeue instructions
            if(bypass) begin
                sc_rd_req_o.valid     <= rs_request_i.rs_entry.occupied;
                sc_rd_req_o.prf_tag   <= rs_request_i.rs_entry.prf_tag;
                sc_rd_req_o.rob_id    <= rs_request_i.rs_entry.rob_id;
                sc_rd_req_o.operation <= rs_request_i.rs_entry.operation;
                sc_rd_req_o.operand_a_tag <= rs_request_i.rs_entry.operand_a_tag;
                sc_rd_req_o.operand_b_tag <= rs_request_i.rs_entry.operand_b_tag;
                sc_rd_req_o.imm <= rs_request_i.rs_entry.imm;
                sc_rd_req_o.read_src2 <= rs_request_i.rs_entry.read_src2;
                
            end
            
            else if(dispatch) begin
                // send slice of ROB entry to output, removing the tags and ready
                sc_rd_req_o.valid     <= buffer[choice].occupied;
                sc_rd_req_o.prf_tag   <= buffer[choice].prf_tag;
                sc_rd_req_o.rob_id    <= buffer[choice].rob_id;
                sc_rd_req_o.operation <= buffer[choice].operation;

                sc_rd_req_o.operand_a_tag <= buffer[choice].operand_a_tag;
                sc_rd_req_o.operand_b_tag <= buffer[choice].operand_b_tag;

                sc_rd_req_o.imm    <= buffer[choice].imm;
                sc_rd_req_o.read_src2    <= buffer[choice].read_src2;
                
                // clearing buffer entry and sending released value
                buffer[choice] <= '0;
            end
            else sc_rd_req_o <= '0;
            
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

    assign rs_slot_released_o = sc_rd_req_o.valid;

endmodule