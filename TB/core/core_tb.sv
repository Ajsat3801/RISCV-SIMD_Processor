module core_tb;

    logic clk, reset_n;
    logic fetch_valid, sc_pre_load, vc_pre_load;
    signal_pkg::data_t raw_instr, pc, sc_pre_load_data;
    signal_pkg::vector_data_t vc_pre_load_data;
    signal_pkg::prf_tag_t sc_pre_load_addr, vc_pre_load_addr;
    logic ready;

    signal_pkg::arf_address_t prev_dest_address, vc_prev_dest_address;
    signal_pkg::prf_tag_t prev_prf_tag, vc_prev_prf_tag;
    logic prev_retire_sc, prev_retire_vc;
    
    int cycles;

    signal_pkg::data_t instr_array[];

    core dut(
        .clk_i(clk),
        .reset_ni(reset_n),
        .fetched_instr_i(raw_instr),
        .pc_i(pc),
        .fetch_valid_i(fetch_valid),
        .sc_pre_load_i(sc_pre_load),
        .sc_pre_load_addr_i(sc_pre_load_addr),
        .sc_pre_load_data_i(sc_pre_load_data),
        .vc_pre_load_i(vc_pre_load),
        .vc_pre_load_addr_i(vc_pre_load_addr),
        .vc_pre_load_data_i(vc_pre_load_data),
        .ready_o(ready)
    );

    initial begin
        clk = 1'b0;
        #10;
        forever #10 clk = ~clk;
    end

    initial begin
        instr_array = '{ 
            32'b00000000001000001000000110110011, // ADD R3 R1 R2 -> result = 3
            32'b01100000000100010000001000110011, // SUB R4 R2 R1 -> result = 1
            32'b00000000001100100000001010110011, // ADD R5 R3 R4 -> result = 4
            32'b00000010010100010000001100110011, // MUL R6 R2 R5 -> result = 8
            32'b00000010010100110101001110110011, // DIV R7 R6 R5 -> result = 2
            32'b00000000001000001000000111010111  // VADD.VV V3 V1 V2 
        };
    end

    task automatic init();
        reset_n = 1'b0;
        fetch_valid = 1'b0;
        sc_pre_load = 1'b0;
        raw_instr = '0;
        pc = '0;
        sc_pre_load_addr = '0;
        sc_pre_load_data = '0;
        cycles = 0;
        vc_pre_load = 1'b0;
        vc_pre_load_addr = '0;
        vc_pre_load_data = '0;

        repeat (3) @(posedge clk);
        reset_n = 1'b1;
        repeat (3) @(posedge clk);
    endtask

    task automatic preload();

        @(negedge clk);
        sc_pre_load <= 1'b1;
        sc_pre_load_addr <= 7'b0000001;
        sc_pre_load_data <= 7'b0000001;
        
        vc_pre_load <= 1'b1;
        vc_pre_load_addr <= 7'b1000001;
        vc_pre_load_data <= {4{32'd1}};

        @(negedge clk);
        sc_pre_load <= 1'b1;
        sc_pre_load_addr <= 7'b0000010;
        sc_pre_load_data <= 7'b0000010;
        
        vc_pre_load <= 1'b1;
        vc_pre_load_addr <= 7'b1000010;
        vc_pre_load_data <= {4{32'd2}};

        @(negedge clk);
        sc_pre_load <= 1'b0;
        sc_pre_load_addr <= '0;
        sc_pre_load_data <= '0;

        vc_pre_load <= 1'b0;
        vc_pre_load_addr <= '0;
        vc_pre_load_data <= '0;

        cycles = 0;
        $display("----------------------------------------------------------------------------------------------------");
        $display("                                                BEGIN TEST");    
        $display("----------------------------------------------------------------------------------------------------");
    endtask

    task automatic display_commit_states_sc();
        $display("[FINAL] R1:%h %h R2:%h %h R3:%h %h R4:%h %h R5:%h %h R6:%h %h R7:%h %h",
            dut.u_scalar_prf_replica0.regfile[dut.u_alloc_rename_retire.sc_commit_table[1]],
            dut.u_scalar_prf_replica1.regfile[dut.u_alloc_rename_retire.sc_commit_table[1]],
            dut.u_scalar_prf_replica0.regfile[dut.u_alloc_rename_retire.sc_commit_table[2]],
            dut.u_scalar_prf_replica1.regfile[dut.u_alloc_rename_retire.sc_commit_table[2]],
            dut.u_scalar_prf_replica0.regfile[dut.u_alloc_rename_retire.sc_commit_table[3]],
            dut.u_scalar_prf_replica1.regfile[dut.u_alloc_rename_retire.sc_commit_table[3]],
            dut.u_scalar_prf_replica0.regfile[dut.u_alloc_rename_retire.sc_commit_table[4]],
            dut.u_scalar_prf_replica1.regfile[dut.u_alloc_rename_retire.sc_commit_table[4]],
            dut.u_scalar_prf_replica0.regfile[dut.u_alloc_rename_retire.sc_commit_table[5]],
            dut.u_scalar_prf_replica1.regfile[dut.u_alloc_rename_retire.sc_commit_table[5]],
            dut.u_scalar_prf_replica0.regfile[dut.u_alloc_rename_retire.sc_commit_table[6]],
            dut.u_scalar_prf_replica1.regfile[dut.u_alloc_rename_retire.sc_commit_table[6]],
            dut.u_scalar_prf_replica0.regfile[dut.u_alloc_rename_retire.sc_commit_table[7]],
            dut.u_scalar_prf_replica1.regfile[dut.u_alloc_rename_retire.sc_commit_table[7]]
        );
    endtask

    task automatic display_commit_states_vc();
        $display("[FINAL] R1:%h R2:%h R3:%h R4:%h R5:%h R6:%h R7:%h",
            dut.u_vector_prf.regfile[dut.u_alloc_rename_retire.vc_commit_table[1]],
            dut.u_vector_prf.regfile[dut.u_alloc_rename_retire.vc_commit_table[2]],
            dut.u_vector_prf.regfile[dut.u_alloc_rename_retire.vc_commit_table[3]],
            dut.u_vector_prf.regfile[dut.u_alloc_rename_retire.vc_commit_table[4]],
            dut.u_vector_prf.regfile[dut.u_alloc_rename_retire.vc_commit_table[5]],
            dut.u_vector_prf.regfile[dut.u_alloc_rename_retire.vc_commit_table[6]],
            dut.u_vector_prf.regfile[dut.u_alloc_rename_retire.vc_commit_table[7]]
        );
    endtask

    task automatic display_final_prf_state_sc0();
        $display("                  FINAL STATE SCALAR PRF1");
        for(int i=0; i<32; i+=4) begin
            $display("R%02d: %h\t| R%02d: %h\t| R%02d: %h\t| R%02d: %h",
                    i  , dut.u_scalar_prf_replica0.regfile[dut.u_alloc_rename_retire.sc_commit_table[i]],
                    i+1, dut.u_scalar_prf_replica0.regfile[dut.u_alloc_rename_retire.sc_commit_table[i+1]],
                    i+2, dut.u_scalar_prf_replica0.regfile[dut.u_alloc_rename_retire.sc_commit_table[i+2]],
                    i+3, dut.u_scalar_prf_replica0.regfile[dut.u_alloc_rename_retire.sc_commit_table[i+3]],
                    );
        end
        $display("----------------------------------------------------------------------------------------------------");
    endtask

    task automatic display_final_prf_state_sc1();
        $display("                  FINAL STATE SCALAR PRF1");
        for(int i=0; i<32; i+=4) begin
            $display("R%02d: %h\t| R%02d: %h\t| R%02d: %h\t| R%02d: %h",
                    i  , dut.u_scalar_prf_replica1.regfile[dut.u_alloc_rename_retire.sc_commit_table[i]],
                    i+1, dut.u_scalar_prf_replica1.regfile[dut.u_alloc_rename_retire.sc_commit_table[i+1]],
                    i+2, dut.u_scalar_prf_replica1.regfile[dut.u_alloc_rename_retire.sc_commit_table[i+2]],
                    i+3, dut.u_scalar_prf_replica1.regfile[dut.u_alloc_rename_retire.sc_commit_table[i+3]],
                    );
        end
        $display("----------------------------------------------------------------------------------------------------");
    endtask

    task automatic display_final_prf_state_vc();
        $display("                  FINAL STATE VECTOR PRF");
        for(int i=0; i<32; i++) begin
            $display("V%02d: %h %h %h %h", 
                    i, 
                    dut.u_vector_prf.regfile[dut.u_alloc_rename_retire.vc_commit_table[i]][3],
                    dut.u_vector_prf.regfile[dut.u_alloc_rename_retire.vc_commit_table[i]][2],
                    dut.u_vector_prf.regfile[dut.u_alloc_rename_retire.vc_commit_table[i]][1],
                    dut.u_vector_prf.regfile[dut.u_alloc_rename_retire.vc_commit_table[i]][0]
                );
        end
        $display("----------------------------------------------------------------------------------------------------");
    endtask

    task automatic display_prf_sc();
        $display("[SC PRF] R1:%h %h R2:%h %h R3:%h %h R4:%h %h R5:%h %h R6:%h %h R7:%h %h",
            dut.u_scalar_prf_replica0.regfile[1],
            dut.u_scalar_prf_replica1.regfile[1],
            dut.u_scalar_prf_replica0.regfile[2],
            dut.u_scalar_prf_replica1.regfile[2],
            dut.u_scalar_prf_replica0.regfile[32],
            dut.u_scalar_prf_replica1.regfile[32],
            dut.u_scalar_prf_replica0.regfile[33],
            dut.u_scalar_prf_replica1.regfile[33],
            dut.u_scalar_prf_replica0.regfile[34],
            dut.u_scalar_prf_replica1.regfile[34],
            dut.u_scalar_prf_replica0.regfile[35],
            dut.u_scalar_prf_replica1.regfile[35],
            dut.u_scalar_prf_replica0.regfile[36],
            dut.u_scalar_prf_replica1.regfile[36]
        );
    endtask

    task automatic display_prf_vc();
        $display("[VC PRF] R1:%h R2:%h R3:%h",
            dut.u_vector_prf.regfile[1],
            dut.u_vector_prf.regfile[2],
            dut.u_vector_prf.regfile[32],
        );
    endtask

    task automatic display_prf_inout_sc();
        $display("[PRF IN] [%b @ %d (%h)]",
            dut.u_scalar_prf_replica0.sc_wb_instr_i.valid,
            dut.u_scalar_prf_replica0.sc_wb_instr_i.prf_tag,
            dut.u_scalar_prf_replica0.sc_wb_instr_i.data
        );
    endtask
    task automatic display_prf_inout_vc();
        $display("[PRF INOUT] IN:[%b @ %0d (%b %b)] OUT:[%b - %h %h]",
            dut.u_vector_prf.vc_alu_rd_req_i.valid,
            dut.u_vector_prf.vc_alu_rd_req_i.prf_tag,
            dut.u_vector_prf.vc_alu_rd_req_i.operand_a_tag,
            dut.u_vector_prf.vc_alu_rd_req_i.operand_b_tag,
            dut.u_vector_prf.vc_alu_ex_req_o.valid,
            dut.u_vector_prf.vc_alu_ex_req_o.operand_a,
            dut.u_vector_prf.vc_alu_ex_req_o.operand_b
        );
    endtask

    task automatic display_stage_valids();             
        $display("[SC CORE] fetch=%h, decode=%h, queue=%h, alloc=%h %h %0d, rs=%h %h %h %h, ex=%h %h %h %h, wb=%h %h, retire=%h (%0d)",
                dut.u_decode.fetch_valid_i,
                dut.u_decode.decoded_instr_o.valid, 
                dut.u_instr_q.dispatched_instr_o.valid,
                dut.u_alloc_rename_retire.alloc_instr_o.sc_valid, dut.u_alloc_rename_retire.alloc_instr_o.vc_valid,
                dut.u_alloc_rename_retire.alloc_instr_o.instr.dest_address,
                dut.u_scalar_alu_rs.sc_rd_req0_o.valid, dut.u_scalar_alu_rs.sc_rd_req1_o.valid,
                dut.u_scalar_muldiv_rs.sc_rd_req_o.valid, dut.u_vector_alu_rs.vc_read_request_o.valid,
                dut.u_scalar_alu0.sc_ex_result_o.valid, dut.u_scalar_alu1.sc_ex_result_o.valid,
                dut.u_scalar_muldiv.sc_ex_result_o.valid, dut.u_vector_alu.vc_ex_result_o.valid,
                dut.u_scalar_writeback.data_bus_o.valid, dut.u_vector_writeback.data_bus_o.valid,
                dut.u_reorder_buffer.retire_instr_o.valid, dut.u_reorder_buffer.retire_instr_o.prf_tag
        );
    endtask

    task automatic display_rs_states_sc();
        $display("[SC RS] in:[%b @ %0d (%h %h)] ready:%b %b out:[%0d %0d %b %b]",
                dut.u_scalar_alu_rs.rs_request_i.rs_entry.occupied,
                dut.u_scalar_alu_rs.rs_request_i.rs_slot_id,
                dut.u_scalar_alu_rs.rs_request_i.rs_entry.operand_a_ready,
                dut.u_scalar_alu_rs.rs_request_i.rs_entry.operand_b_ready,
                dut.u_scalar_alu_rs.sc_ex0_ready_i,
                dut.u_scalar_alu_rs.sc_ex1_ready_i,
                dut.u_scalar_alu_rs.sc_rd_req0_o.prf_tag,
                dut.u_scalar_alu_rs.sc_rd_req1_o.prf_tag,
                dut.u_scalar_alu_rs.sc_rd_req0_o.valid,
                dut.u_scalar_alu_rs.sc_rd_req1_o.valid
        );
    endtask

    task automatic display_rs_states_vc();
        $display("[VC RS] in:[%b @ %0d (%h %h)] ready:%b out:[%0d %b]",
                dut.u_vector_alu_rs.rs_request_i.rs_entry.occupied,
                dut.u_vector_alu_rs.rs_request_i.rs_slot_id,
                dut.u_vector_alu_rs.rs_request_i.rs_entry.operand_a_ready,
                dut.u_vector_alu_rs.rs_request_i.rs_entry.operand_b_ready,
                dut.u_vector_alu_rs.vc_ex_ready_i,
                dut.u_vector_alu_rs.vc_read_request_o.prf_tag,
                dut.u_vector_alu_rs.vc_read_request_o.valid
        );
    endtask

    task automatic display_arr_states_sc();
        $display("[ARR] out:[%b @ %0d (%h %h)] [RS] in:[%b @ %0d (%h %h)] ",
                dut.u_alloc_rename_retire.alloc_instr_o.sc_valid,
                dut.u_alloc_rename_retire.alloc_instr_o.rs_slot_id,
                dut.u_alloc_rename_retire.alloc_instr_o.operand_a_ready,
                dut.u_alloc_rename_retire.alloc_instr_o.operand_b_ready,
                dut.u_scalar_alu_rs.rs_request_i.rs_entry.occupied,
                dut.u_scalar_alu_rs.rs_request_i.rs_slot_id,
                dut.u_scalar_alu_rs.rs_request_i.rs_entry.operand_a_ready,
                dut.u_scalar_alu_rs.rs_request_i.rs_entry.operand_b_ready
        );
    endtask

    task automatic display_arr_states_vc();
        $display("[ARR] out:[%b @ %0d (%h %h)] [RS] in:[%b @ %0d (%h %h)] ",
                dut.u_alloc_rename_retire.alloc_instr_o.vc_valid,
                dut.u_alloc_rename_retire.alloc_instr_o.rs_slot_id,
                dut.u_alloc_rename_retire.alloc_instr_o.operand_a_ready,
                dut.u_alloc_rename_retire.alloc_instr_o.operand_b_ready,
                dut.u_vector_alu_rs.rs_request_i.rs_entry.occupied,
                dut.u_vector_alu_rs.rs_request_i.rs_slot_id,
                dut.u_vector_alu_rs.rs_request_i.rs_entry.operand_a_ready,
                dut.u_vector_alu_rs.rs_request_i.rs_entry.operand_b_ready
        );
    endtask

    task automatic display_vc_alu_states();
        $display("[VC ALU] IN:[%b @ %0d - %h %h], OUT:[%b @ %0d - %h]",
            dut.u_vector_alu.vc_ex_request_i.valid,
            dut.u_vector_alu.vc_ex_request_i.rob_id,
            dut.u_vector_alu.vc_ex_request_i.operand_a,
            dut.u_vector_alu.vc_ex_request_i.operand_b,
            dut.u_vector_alu.vc_ex_result_o.valid,
            dut.u_vector_alu.vc_ex_result_o.rob_id,
            dut.u_vector_alu.vc_ex_result_o.data
        );
    endtask

    task automatic send_instr(int num_instr);
        int n = 0;
        
        repeat(num_instr) begin
            @(negedge clk);
            raw_instr <= instr_array[n];
            fetch_valid = 1'b1;
            n++;
            
        end
         @(negedge clk);
        fetch_valid = 1'b0;
        raw_instr <= '0;
    endtask

    always @(posedge clk) begin;
        prev_dest_address <= dut.u_alloc_rename_retire.retire_instr_i.dest_address;
        prev_prf_tag      <= dut.u_alloc_rename_retire.retire_instr_i.prf_tag;
        prev_retire_sc    <= dut.u_alloc_rename_retire.retire_instr_i.valid && !dut.u_alloc_rename_retire.retire_instr_i.prf_tag.vector;
        prev_retire_vc    <= dut.u_alloc_rename_retire.retire_instr_i.valid && dut.u_alloc_rename_retire.retire_instr_i.prf_tag.vector;
        if(prev_retire_sc) begin
        $display("[sc Retire at cycle %0d (%0t ns)] \tR%0d \ttag:%0d \tval:%h",
            (cycles-1), ($time()-20),
            prev_dest_address,
            prev_prf_tag,
            dut.u_scalar_prf_replica0.regfile[dut.u_alloc_rename_retire.sc_commit_table[prev_dest_address]]
        );
        end
        if(prev_retire_vc) begin
        $display("[vc Retire at cycle %0d (%0t ns)] \tV%0d \ttag:%0d \tval:%h",
            (cycles-1), ($time()-20),
            prev_dest_address,
            prev_prf_tag,
            dut.u_vector_prf.regfile[dut.u_alloc_rename_retire.vc_commit_table[prev_dest_address]]
        );
        end
    end

    initial begin
        init();
        preload();
        send_instr(instr_array.size());

    end

    always @(posedge clk) begin
        #1;
        cycles++;
        //display_commit_states_sc();
        //display_commit_states_vc();
        //display_stage_valids();
        //display_prf_sc();
        //display_prf_vc();
        //display_prf_inout_sc();
        //display_prf_inout_vc();
        //display_vc_alu_states();
        //display_rs_states();
        //display_rs_states_vc();
        //display_arr_states_sc();
        //display_arr_states_vc();
        if(cycles >= 80) begin
            $display("----------------------------------------------------------------------------------------------------");
            $display("                                           RUN COMPLETE"); 
            $display("----------------------------------------------------------------------------------------------------");
            display_final_prf_state_sc0();
            display_final_prf_state_sc1();
            display_final_prf_state_vc();
            $finish;
        end
    end
endmodule