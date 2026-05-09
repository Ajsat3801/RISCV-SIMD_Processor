
    module ex_load_store(
        input logic clk_i,
        input logic reset_ni,
        input logic flush_i,

        input  signal_pkg::sc_ex_request_t lsu_request_i,
        input  signal_pkg::data_t sc_store_data_i,
        input  signal_pkg::vc_lsu_ex_request_t vc_lsu_ex_request_i,

        if_retirement_bus.lsu retire_instr_i,

        output packet_pkg::load_store_entry_t lsu_output_o,
        output packet_pkg::store_retire_t store_retire_o,

        output logic sc_ex_ready_o,
        output logic vc_ex_ready_o
    );

    packet_pkg::load_store_entry_t store_buffer[config_pkg::STORE_BUFFER_SIZE-1:0];
    packet_pkg::load_store_entry_t in, store_out, holding_reg;
    logic[config_pkg::STORE_BUFFER_SIZE-1:0] available;
    logic hold;

    logic[$clog2(config_pkg::STORE_BUFFER_SIZE)-1:0] in_idx, out_idx;
    logic send_store, send_hold, send_in;

    always_comb begin
        // Combine scalar and vector inputs into a single packet
        in.valid     =  lsu_request_i.valid;
        in.is_store  =  (lsu_request_i.operation.lsu  == signal_pkg::LSU_SW) ||
                        (lsu_request_i.operation.vlsu == signal_pkg::VLSU_VSE32);
        in.is_vector =  vc_lsu_ex_request_i.a_is_vector || vc_lsu_ex_request_i.b_is_vector;

        in.rob_id    =  lsu_request_i.rob_id;
        in.mem_addr  =  lsu_request_i.operand_a + lsu_request_i.operand_b;
        
        if(in.is_vector) in.data = vc_lsu_ex_request_i.store_data;
        else begin
            in.data = '0;
            in.data [in.mem_addr[1:0]] = sc_store_data_i;
        end   

        // Calculating in and out indices
        // can retire only 1 instruction at a time so only 1 valid comparison possible. 
        out_idx = '0;
        in_idx  = '0;

        for(int i=0; i<STORE_BUFFER_SIZE; i++) begin
            if(!store_buffer[i].valid) in_idx = i;
            if(store_buffer[i].rob_id == retire_instr_i.rob_id) out_idx = i;
        end

        // intermediate logic variables
        send_store = retire_instr_i.valid && store_out.valid;
        send_hold  = hold && !send_store;
        send_in    = in.valid && !in.is_store && !hold && !send_store;

    end

    always_ff @(posedge clk) begin
        if(!reset_n || flush_i) begin
            for(int i=0; i<STORE_BUFFER_SIZE; i++) begin
                store_buffer[i] <= '0;
                available[i]    <= '1;
                hold <= 1'b0;
                hold_reg <= '0;
            end
        end
        else begin
            if(in.valid && in.is_store) begin
                store_buffer[in_idx]  <= in;
                available[in_idx]     <= 1'b0;
                store_retire_o.valid  <= 1'b1;
                store_retire_o.rob_id <= in.rob_id;
            end
            else begin
                store_retire_o.valid  <= 1'b0;
                store_retire_o.rob_id <= '0;
            end
            unique case(1)
                send_store: begin
                    lsu_output_o <= store_buffer[out_idx];
                    
                    available[out_idx]    <= 1'b1;
                    store_buffer[out_idx] <= '0;
                    
                    if(in.valid && !in.is_store) begin
                        hold_reg <= in;
                        hold     <= 1'b1;
                    end
                end
                send_hold: begin
                    lsu_output_o <= hold_reg;
                    hold_reg <= '0;
                    hold     <= 1'b0;
                end
                send_in : lsu_output_o <= in;
                default : lsu_output_o <= '0;
            endcase
        end
    end

    assign sc_ex_ready_o = |available && !hold;
    assign vc_ex_ready_o = |available && !hold;

endmodule