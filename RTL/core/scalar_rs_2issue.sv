//import config_pkg::*;

module scalar_rs_2issue #(
    parameter chip_select_e CHIP_SELECT = CS_SALU
)(
    input logic clk_i,
    input logic reset_ni,
    input logic flush_i,
    
    // connection with operation bus 
    operand_bus_if.rs rs_input_i,

    // connection with common data bus
    data_bus_if.snoop s_data_bus_i,

    // connection with instruction queue
    output instr_pkg::rs_slot_id_t released_rs_slot_id_o[1:0],
    output logic rs_slot_released_o[1:0],

    // output to execution unit
    input ex1_ready_i,
    input ex2_ready_i,
    output signal_pkg::rs_to_alu_signal_t dispatch1_o,
    output signal_pkg::rs_to_alu_signal_t dispatch2_o
);

    storage_pkg::rs_entry_t buffer[DUAL_SLOT_RS_LEN-1:0];
    instr_pkg::rs_slot_id_t choice, choice_next;

    logic grant1, grant2;
    instr_pkg::rs_slot_id_t grant1_idx, grant2_idx;
    instr_pkg::rs_slot_id_t dispatch_idx1, dispatch_idx2;
    logic grant1_to_dispatch1, grant1_to_dispatch2, grant2_to_dispatch2;
    logic bypass_to_dispatch1, bypass_to_dispatch2;

    logic[DUAL_SLOT_RS_LEN-1:0] occupied, operands_ready, snoop, eligible;
    logic instr_valid, any_eligible, bypass_eligible;

    int i, i_ff;

    always_comb begin

        instr_valid = rs_input_i.rs_entry.occupied && rs_input_i.chip_select == CHIP_SELECT;
        
        for(i=0;i<DUAL_SLOT_RS_LEN;i++) begin
            occupied[i] = buffer[i].occupied;
            operands_ready[i] = buffer[i].operand_a_ready && buffer[i].operand_b_ready;
        end

        snoop    = occupied & ~operands_ready;
        eligible = occupied & operands_ready;
        any_eligible = ~|eligible;
        
        grant1 = 1'b0;
        grant2 = 1'b0;
        grant1_idx = choice;
        grant2_idx = choice;

        for(i=choice; i<DUAL_SLOT_RS_LEN; i++) begin
            if(eligible[i]) begin
                if(!grant1) begin
                    grant1_idx = i;
                    grant1 = 1'b1;
                end
                else if(!grant2) begin
                    grant2_idx = i;
                    grant2 = 1'b1;
                end
            end
        end
        if(grant1 || grant2) begin
            for(i=0; i<choice; i++) begin
                if(!grant1) begin
                    grant1_idx = i;
                    grant1 = 1'b1;
                end
                else if(!grant2) begin
                    grant2_idx = i;
                    grant2 = 1'b1;
                end
            end
        end

        bypass_eligible = instr_valid && rs_input_i.rs_entry.operand_a_ready && rs_input_i.rs_entry.operand_b_ready;

        /*
            at this stage
            grant1 <- first instruction thats ready to be dispatched (address choice_idx_1)
            grant2 <- second instruction ready to be dispatched (choice_idx_2)
            eligible bypass <- the input instruction can be dispatched if we dont have 2 instructions
        */

        grant1_to_dispatch1 = ex1_ready_i && grant1;
        bypass_to_dispatch1 = ex1_ready_i && !grant1 && bypass_eligible;

        grant1_to_dispatch2 = ex2_ready_i && !ex1_ready_i && grant1;
        grant2_to_dispatch2 = ex2_ready_i && grant1_to_dispatch1 && grant2;
        bypass_to_dispatch2 = ex2_ready_i && !bypass_to_dispatch1 && !grant1_to_dispatch2 && !grant2_to_dispatch2 && bypass_eligible;

        if(bypass_to_dispatch2 || bypass_to_dispatch1) choice_next = rs_input_i.rs_slot + 1'b1;
        else if(grant2_to_dispatch2) choice_next = grant2_idx + 1'b1;
        else if(grant1_to_dispatch1 || grant1_to_dispatch2) choice_next = grant1_idx + 1'b1;
        else choice_next = choice;

    end

    always_ff @(posedge clk_i) begin
        
        if (!reset_ni || flush_i) begin
            
            for (i_ff=0; i_ff<DUAL_SLOT_RS_LEN; i_ff++) buffer[i_ff] <= '0;

            rs_slot_released_o[0] <= 1'b0;
            rs_slot_released_o[1] <= 1'b1;

            released_rs_slot_id_o[0] <= '0;
            released_rs_slot_id_o[1] <= '0;

            dispatch1_o <= '0;
            dispatch2_o <= '0;

            choice <= '0;

        end
        else begin

            // snoop data from CDB and update if needed
            if (s_data_bus_i.valid) begin
                for (i_ff=0; i_ff<DUAL_SLOT_RS_LEN; i_ff++) begin
                    if (occupied[i_ff] && s_data_bus_i.prf_tag == buffer[i_ff].operand_a_tag && !buffer[i_ff].operand_a_ready) begin 
                        buffer[i_ff].operand_a <= s_data_bus_i.data;
                        buffer[i_ff].operand_a_ready <= 1'b1;
                    end
                    if(occupied[i_ff] && s_data_bus_i.prf_tag == buffer[i_ff].operand_b_tag && !buffer[i_ff].operand_b_ready) begin
                        buffer[i_ff].operand_b <= s_data_bus_i.data;
                        buffer[i_ff].operand_b_ready <= 1'b1;
                    end
                end
            end

            // dispatch instructions
            if(grant1_to_dispatch1) begin
                dispatch1_o.valid <= 1'b1;
                dispatch1_o.prf_tag   <= buffer[grant1_idx].prf_tag;
                dispatch1_o.rob_id    <= buffer[grant1_idx].rob_id;
                dispatch1_o.operand_a <= buffer[grant1_idx].operand_a;
                dispatch1_o.operand_b <= buffer[grant1_idx].operand_b;
                dispatch1_o.operation <= buffer[grant1_idx].operation;
                dispatch1_o.sign <= buffer[grant1_idx].sign;

                released_rs_slot_id_o[0] <= grant1_idx;
            end
            else if(bypass_to_dispatch1) begin
                dispatch1_o.valid <= 1'b1;
                dispatch1_o.prf_tag   <= rs_input_i.rs_entry.prf_tag;
                dispatch1_o.rob_id    <= rs_input_i.rs_entry.rob_id;
                dispatch1_o.operand_a <= rs_input_i.rs_entry.operand_a;
                dispatch1_o.operand_b <= rs_input_i.rs_entry.operand_b;
                dispatch1_o.operation <= rs_input_i.rs_entry.operation;
                dispatch1_o.sign <= rs_input_i.rs_entry.sign;

                released_rs_slot_id_o[0] <= rs_input_i.rs_slot;
            end
            else begin// default
                dispatch1_o <= '0;
                released_rs_slot_id_o[0] <= '0;
            end

            if(grant1_to_dispatch2) begin
                dispatch2_o.valid <= 1'b1;
                dispatch2_o.prf_tag   <= buffer[grant1_idx].prf_tag;
                dispatch2_o.rob_id    <= buffer[grant2_idx].rob_id;
                dispatch2_o.operand_a <= buffer[grant1_idx].operand_a;
                dispatch2_o.operand_b <= buffer[grant1_idx].operand_b;
                dispatch2_o.operation <= buffer[grant1_idx].operation;
                dispatch2_o.sign <= buffer[grant1_idx].sign;

                released_rs_slot_id_o[1] <= grant1_idx;
            end
            else if(grant2_to_dispatch2) begin
                dispatch2_o.valid <= 1'b1;
                dispatch2_o.prf_tag   <= buffer[grant2_idx].prf_tag;
                dispatch2_o.rob_id    <= buffer[grant2_idx].rob_id;
                dispatch2_o.operand_a <= buffer[grant2_idx].operand_a;
                dispatch2_o.operand_b <= buffer[grant2_idx].operand_b;
                dispatch2_o.operation <= buffer[grant2_idx].operation;
                dispatch2_o.sign <= buffer[grant2_idx].sign;

                released_rs_slot_id_o[1] <= grant2_idx;
            end
            else if(bypass_to_dispatch2) begin
                dispatch2_o.valid <= 1'b1;
                dispatch2_o.prf_tag   <= rs_input_i.rs_entry.prf_tag;
                dispatch2_o.rob_id    <= rs_input_i.rs_entry.rob_id;
                dispatch2_o.operand_a <= rs_input_i.rs_entry.operand_a;
                dispatch2_o.operand_b <= rs_input_i.rs_entry.operand_b;
                dispatch2_o.operation <= rs_input_i.rs_entry.operation;
                dispatch2_o.sign <= rs_input_i.rs_entry.sign;

                released_rs_slot_id_o[1] <= rs_input_i.rs_slot;
            end
            else begin// default
                dispatch2_o <= '0;
                released_rs_slot_id_o[1] <= '0;
            end
            
            choice <= choice_next;

            // instruction issued
            if(instr_valid && !bypass_to_dispatch1 && !bypass_to_dispatch2) buffer[rs_input_i.rs_slot] <= rs_input_i.rs_entry;

        end
    end

endmodule