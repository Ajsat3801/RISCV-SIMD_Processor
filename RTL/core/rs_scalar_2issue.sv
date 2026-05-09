//import config_pkg::*;

module rs_scalar_2issue #(
    parameter signal_pkg::chip_select_e CHIP_SELECT = signal_pkg::CS_SALU
)(
    input  logic clk_i,
    input  logic reset_ni,
    input  logic flush_i,
    
    if_alloc_bus.sc_rs sc_rs_request_i,
    if_data_bus.snoop sc_data_bus_i,

    input  logic sc_ex0_ready_i,
    input  logic sc_ex1_ready_i,

    output packet_pkg::read_request_t sc_rd_req0_o,
    output packet_pkg::read_request_t sc_rd_req1_o,

    output signal_pkg::rs_slot_id_t released_rs_slot_id_o[1:0],
    output logic rs_slot_released_o[1:0]
);

    packet_pkg::rs_entry_t buffer[DUAL_SLOT_RS_LEN-1:0];
    signal_pkg::rs_slot_id_t choice1, choice2;

    logic bypass_to_slot1, bypass_to_slot2;
    logic winner1_to_slot1, winner1_to_slot2, winner2_to_slot2;
    logic instr_valid, bypass_valid;
    logic winner1_valid, winner2_valid;
    logic [DUAL_SLOT_RS_LEN-1:0] mask, mask_next, mask_upper;
    logic [DUAL_SLOT_RS_LEN-1:0] upper_canditates, lower_canditates, canditates2;
    logic [DUAL_SLOT_RS_LEN-1:0] winner_lower, winner_upper, winner1, winner2;
    logic [DUAL_SLOT_RS_LEN-1:0] eligible;
    

    always_comb begin
        
        choice1 = '0;
        choice2 = '0;

        instr_valid =   sc_rs_request_i.rs_entry.occupied && 
                        (sc_rs_request_i.chip_select == CHIP_SELECT);

        bypass_valid =  instr_valid &&
                        sc_rs_request_i.rs_entry.operand_a_ready &&
                        sc_rs_request_i.rs_entry.operand_b_ready;
        
        for (int i=0; i<DUAL_SLOT_RS_LEN; i++) begin
            eligible[i] =   buffer[i].occupied &&
                            buffer[i].operand_a_ready &&
                            buffer[i].operand_b_ready;
        end

        mask_upper[0] = mask[0];

        for (int i=1; i<DUAL_SLOT_RS_LEN; i++) begin
            mask_upper[i] = mask_upper[i-1] | mask[i];
        end

        upper_canditates = eligible & mask_upper;
        lower_canditates = eligible & ~mask_upper;

        winner_upper = upper_canditates & (~upper_canditates + 1'b1);
        winner_lower = lower_canditates & (~lower_canditates + 1'b1);

        winner1 = (|upper_canditates) ? winner_upper : winner_lower;

        canditates2 = eligible & ~winner1;
        winner2 = canditates2 & (~canditates2 + 1'b1);

        winner1_valid = (|upper_canditates) || (|lower_canditates);
        winner2_valid = (|canditates2);

        winner1_to_slot1 =  sc_ex0_ready_i &&  winner1_valid;
        winner1_to_slot2 =  sc_ex1_ready_i &&  winner1_valid && !sc_ex0_ready_i;
        winner2_to_slot2 =  sc_ex1_ready_i &&  winner2_valid &&  sc_ex0_ready_i;
        bypass_to_slot1  =  sc_ex0_ready_i && !winner1_valid && bypass_valid;
        bypass_to_slot2  =  sc_ex1_ready_i && 
                            !winner2_valid &&
                            ((sc_ex0_ready_i &&  winner1_valid) ||
                            (!sc_ex0_ready_i && !winner1_valid)) &&
                            bypass_valid;

        mask_next = mask;

        if (winner1_to_slot1) begin
            for(int i=0;i<DUAL_SLOT_RS_LEN; i++) begin
                if(winner1[i]) choice1 = i[RS_ADDR_W-1:0];
            end
            mask_next = {winner1[DUAL_SLOT_RS_LEN-2:0], winner1[DUAL_SLOT_RS_LEN-1]};
        end
        if (winner1_to_slot2) begin
            for (int i=0;i<DUAL_SLOT_RS_LEN; i++) begin
                if (winner1[i]) choice2 = i[RS_ADDR_W-1:0];
            end
            mask_next = {winner1[DUAL_SLOT_RS_LEN-2:0], winner1[DUAL_SLOT_RS_LEN-1]};
        end
        if (winner2_to_slot2) begin
            for(int i=0;i<DUAL_SLOT_RS_LEN; i++) begin
                if(winner2[i]) choice2 = i[RS_ADDR_W-1:0];
            end
            mask_next = {winner2[DUAL_SLOT_RS_LEN-2:0], winner2[DUAL_SLOT_RS_LEN-1]};
        end
        
    end

    always_ff @(posedge clk_i) begin
        
        if (!reset_ni || flush_i) begin
            
            for (int i=0; i<DUAL_SLOT_RS_LEN; i++) buffer[i] <= '0;

            rs_slot_released_o[0] <= 1'b0;
            rs_slot_released_o[1] <= 1'b0;

            released_rs_slot_id_o[0] <= '0;
            released_rs_slot_id_o[1] <= '0;

            sc_rd_req0_o <= '0;
            sc_rd_req1_o <= '0;

            mask <= {{DUAL_SLOT_RS_LEN-1{1'b0}}, 1'b1};

        end
        else begin

            // snoop data from CDB and update if needed
            if (sc_data_bus_i.valid) begin
                for (int i=0; i<DUAL_SLOT_RS_LEN; i++) begin
                    if (buffer[i].occupied && sc_data_bus_i.prf_tag == buffer[i].operand_a_tag && !buffer[i].operand_a_ready) begin 
                        buffer[i].operand_a_ready <= 1'b1;
                    end
                    if(buffer[i].occupied && sc_data_bus_i.prf_tag == buffer[i].operand_b_tag && !buffer[i].operand_b_ready) begin
                        buffer[i].operand_b_ready <= 1'b1;
                    end
                end
            end

            // dispatch instructions
            if(winner1_to_slot1) begin
                sc_rd_req0_o.valid     <= 1'b1;
                sc_rd_req0_o.prf_tag   <= buffer[choice1].prf_tag;
                sc_rd_req0_o.rob_id    <= buffer[choice1].rob_id;
                sc_rd_req0_o.operation <= buffer[choice1].operation;
                sc_rd_req0_o.operand_a_tag <= buffer[choice1].operand_a_tag;
                sc_rd_req0_o.operand_b_tag <= buffer[choice1].operand_b_tag;
                sc_rd_req0_o.imm       <= buffer[choice1].imm;
                sc_rd_req0_o.read_src2 <= buffer[choice1].read_src2;
                
                released_rs_slot_id_o[0] <= choice1;
                rs_slot_released_o[0] <= 1'b1;

                buffer[choice1] <= '0;
            end
            else if(bypass_to_slot1) begin
                sc_rd_req0_o.valid     <= 1'b1;
                sc_rd_req0_o.prf_tag   <= sc_rs_request_i.rs_entry.prf_tag;
                sc_rd_req0_o.rob_id    <= sc_rs_request_i.rs_entry.rob_id;
                sc_rd_req0_o.operation <= sc_rs_request_i.rs_entry.operation;
                sc_rd_req0_o.operand_a_tag <= sc_rs_request_i.rs_entry.operand_a_tag;
                sc_rd_req0_o.operand_b_tag <= sc_rs_request_i.rs_entry.operand_b_tag;
                sc_rd_req0_o.imm       <= sc_rs_request_i.rs_entry.imm;
                sc_rd_req0_o.read_src2 <= sc_rs_request_i.rs_entry.read_src2;
                
                released_rs_slot_id_o[0] <= sc_rs_request_i.rs_slot;
                rs_slot_released_o[0] <= 1'b1;
            end
            else begin// default
                sc_rd_req0_o <= '0;
                rs_slot_released_o[0] <= 1'b0;
                released_rs_slot_id_o[0] <= '0;
            end

            if(winner1_to_slot2) begin
                sc_rd_req1_o.valid     <= 1'b1;
                sc_rd_req1_o.prf_tag   <= buffer[choice1].prf_tag;
                sc_rd_req1_o.rob_id    <= buffer[choice1].rob_id;
                sc_rd_req1_o.operation <= buffer[choice1].operation;
                sc_rd_req1_o.operand_a_tag <= buffer[choice1].operand_a_tag;
                sc_rd_req1_o.operand_b_tag <= buffer[choice1].operand_b_tag;
                sc_rd_req1_o.imm       <= buffer[choice1].imm;
                sc_rd_req1_o.read_src2 <= buffer[choice1].read_src2;

                released_rs_slot_id_o[1] <= choice1;
                rs_slot_released_o[1] <= 1'b1;

                buffer[choice1] <= '0;
            end
            else if(winner2_to_slot2) begin
                sc_rd_req1_o.valid     <= 1'b1;
                sc_rd_req1_o.prf_tag   <= buffer[choice2].prf_tag;
                sc_rd_req1_o.rob_id    <= buffer[choice2].rob_id;
                sc_rd_req1_o.operation <= buffer[choice2].operation;
                sc_rd_req1_o.operand_a_tag <= buffer[choice2].operand_a_tag;
                sc_rd_req1_o.operand_b_tag <= buffer[choice2].operand_b_tag;
                sc_rd_req1_o.imm       <= buffer[choice2].imm;
                sc_rd_req1_o.read_src2 <= buffer[choice2].read_src2;

                released_rs_slot_id_o[1] <= choice2;
                rs_slot_released_o[1] <= 1'b1;

                buffer[choice2] <= '0;
            end
            else if(bypass_to_slot2) begin
                sc_rd_req1_o.valid     <= 1'b1;
                sc_rd_req1_o.prf_tag   <= sc_rs_request_i.rs_entry.prf_tag;
                sc_rd_req1_o.rob_id    <= sc_rs_request_i.rs_entry.rob_id;
                sc_rd_req1_o.operation     <= sc_rs_request_i.rs_entry.operation;
                sc_rd_req1_o.operand_a_tag <= sc_rs_request_i.rs_entry.operand_a_tag;
                sc_rd_req1_o.operand_b_tag <= sc_rs_request_i.rs_entry.operand_b_tag;
                sc_rd_req1_o.imm       <= sc_rs_request_i.rs_entry.imm;
                sc_rd_req1_o.read_src2 <= sc_rs_request_i.rs_entry.read_src2;

                released_rs_slot_id_o[1] <= sc_rs_request_i.rs_slot;
                rs_slot_released_o[1] <= 1'b1;
            end
            else begin// default
                sc_rd_req1_o <= '0;
                rs_slot_released_o[1] <= 1'b0;
                released_rs_slot_id_o[1] <= '0;
            end
            
            mask <= mask_next;

            // instruction issued
            if(instr_valid && !bypass_to_slot1 && !bypass_to_slot2) begin
                 buffer[sc_rs_request_i.rs_slot] <= sc_rs_request_i.rs_entry;
            end

        end
    end

endmodule