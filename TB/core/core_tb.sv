module core_tb;

    logic clk, reset_n;
    logic fetch_valid, sc_pre_load, vc_pre_load;
    instr_pkg::data_t raw_instr, pc, sc_pre_load_data;
    instr_pkg::vector_data_t vc_pre_load_data;
    instr_pkg::prf_tag_t sc_pre_load_addr, vc_pre_load_addr;
    logic ready;

    instr_pkg::arf_address_t prev_dest_address, vc_prev_dest_address;
    instr_pkg::prf_tag_t prev_prf_tag, vc_prev_prf_tag;
    logic prev_retire, vc_prev_retire;
    
    int cycles;

    instr_pkg::data_t instr_array[0:4];

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
            32'b00000000001000001000000110110011, // ADD R3 R1 R2
            32'b01100000000100010000001000110011, // SUB R4 R2 R1
            32'b00000000001100100000001010110011, // ADD R5 R3 R4
            32'b00000010010100010000001100110011, // MUL R6 R2 R5
            32'b00000010010100110101001110110011  // DIV R7 R6 R5
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
        $display("---------------------------------------------------------------------------------");
        $display("                                    BEGIN TEST");
        $display("---------------------------------------------------------------------------------");
    endtask

    task automatic display_commit_states_sc();
        $display("[FINAL] R1:%h R2:%h R3:%h R4:%h R5:%h R6:%h R7:%h",
            dut.u_scalar_prf.regfile[dut.u_scalar_arr.commit_table[1]],
            dut.u_scalar_prf.regfile[dut.u_scalar_arr.commit_table[2]],
            dut.u_scalar_prf.regfile[dut.u_scalar_arr.commit_table[3]],
            dut.u_scalar_prf.regfile[dut.u_scalar_arr.commit_table[4]],
            dut.u_scalar_prf.regfile[dut.u_scalar_arr.commit_table[5]],
            dut.u_scalar_prf.regfile[dut.u_scalar_arr.commit_table[6]],
            dut.u_scalar_prf.regfile[dut.u_scalar_arr.commit_table[7]]
        );
    endtask

    task automatic display_stage_valids();             
        $display("[SC CORE] fetch=%h, decode=%h, queue=%h, alloc=%h %0d, load=%h , rs=%h %h %h, ex=%h %h %h, wb=%h, retire=%h",
                dut.u_decode.fetch_valid_i,
                dut.u_decode.decoded_instr_o.valid, 
                dut.u_instr_q.dispatched_instr_o.valid,
                dut.u_scalar_arr.alloc_instr_o.valid,
                dut.u_scalar_arr.alloc_instr_o.instr.dest_address,
                dut.u_sc_request_bus.rs_entry.occupied,
                dut.u_scalar_alu_rs.sc_ex0_request_o.valid, dut.u_scalar_alu_rs.sc_ex1_request_o.valid,
                dut.u_scalar_muldiv_rs.sc_ex_request_o.valid,
                dut.u_scalar_alu0.sc_ex_result_o.valid, dut.u_scalar_alu1.sc_ex_result_o.valid,
                dut.u_scalar_muldiv.sc_ex_result_o.valid,
                dut.u_scalar_writeback.data_bus_o.valid,
                dut.u_reorder_buffer.retire_instr_o.valid
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
        prev_dest_address <= dut.u_scalar_arr.retire_instr_i.dest_address;
        prev_prf_tag      <= dut.u_scalar_arr.retire_instr_i.prf_tag;
        prev_retire       <= dut.u_scalar_arr.retire_instr_i.valid && !dut.u_scalar_arr.retire_instr_i.prf_tag.vector;

        if(prev_retire) begin
        $display("[sc Retire at cycle %0d (%0t ns)] \tR%0d \ttag:%0d \tval:%h",
            (cycles-1), ($time()-20),
            prev_dest_address,
            prev_prf_tag,
            dut.u_scalar_prf.regfile[dut.u_scalar_arr.commit_table[prev_dest_address]]
        );
        end
    end

    always @(posedge clk) begin;
        vc_prev_dest_address <= dut.u_vector_arr.retire_instr_i.dest_address;
        vc_prev_prf_tag      <= dut.u_vector_arr.retire_instr_i.prf_tag;
        vc_prev_retire       <= dut.u_vector_arr.retire_instr_i.valid && dut.u_vector_arr.retire_instr_i.prf_tag.vector;

        if(vc_prev_retire) begin
        $display("[vc Retire at cycle %0d (%0t ns)] \tR%0d \ttag:%0d \tval:%h",
            (cycles-1), ($time()-20),
            vc_prev_dest_address,
            vc_prev_prf_tag,
            dut.u_vector_prf.regfile[dut.u_vector_arr.commit_table[vc_prev_dest_address]]
        );
        end
    end

    initial begin
        init();
        preload();
        send_instr(5);

    end

    always @(posedge clk) begin
        #1;
        cycles++;
        //display_commit_states_sc();
        //display_stage_valids();
        if(cycles >= 256) $finish;
    end
endmodule