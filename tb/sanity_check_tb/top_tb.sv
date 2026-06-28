// Sanity check testbench for core + imem + dmem



module top_tb;

    logic clk, reset_n;
    logic compute;
    logic imem_preload_en, dmem_preload_en;

    packet_pkg::imem_request_t imem_preload_request;
    packet_pkg::dmem_request_t dmem_preload_request;

    logic sc_prf_preload_en, vc_prf_preload_en;
    signal_pkg::prf_tag_t sc_prf_preload_addr, vc_prf_preload_addr;
    signal_pkg::data_t sc_prf_preload_data;
    signal_pkg::vector_data_t vc_prf_preload_data;

    signal_pkg::arf_address_t prev_dest_address, vc_prev_dest_address;
    signal_pkg::prf_tag_t prev_prf_tag, vc_prev_prf_tag;
    logic prev_retire_sc, prev_retire_vc, prev_we;

    int cycles;

    top dut(
        .clk_i(clk),
        .reset_ni(reset_n),

        .compute_i(compute),

        .imem_preload_en_i(imem_preload_en),
        .preload_imem_request_i(imem_preload_request),

        .dmem_preload_en_i(dmem_preload_en),
        .preload_dmem_request_i(dmem_preload_request),

        .sc_prf_preload_en_i(sc_prf_preload_en),
        .sc_prf_preload_data_i(sc_prf_preload_data),
        .sc_prf_preload_addr_i(sc_prf_preload_addr), 

        .vc_prf_preload_en_i(vc_prf_preload_en),
        .vc_prf_preload_data_i(vc_prf_preload_data),
        .vc_prf_preload_addr_i(vc_prf_preload_addr)
        
    );

    initial begin
        clk = 1'b0;
        #10;
        forever #10 clk = ~clk;
    end

    `include "test_program.sv"

    task automatic init();
        cycles  = 0;
        reset_n = 1'b0;
        compute = 1'b0;
        
        imem_preload_en = 1'b0;
        imem_preload_request = '0;

        dmem_preload_en = 1'b0;
        dmem_preload_request = '0;

        sc_prf_preload_en   = 1'b0;
        sc_prf_preload_data = '0;
        sc_prf_preload_addr = '0;

        vc_prf_preload_en   = 1'b0;
        vc_prf_preload_data = '0;
        vc_prf_preload_addr = '0;

        repeat (3) @(posedge clk);
        reset_n = 1'b1;
        repeat (3) @(posedge clk);
    endtask

    task automatic preload_sc_prf();
        int n = 1;
        
        repeat(sc_prf_array.size()) begin
            @(negedge clk);
            sc_prf_preload_en   <= 1'b1;
            sc_prf_preload_addr <= '{vector: 1'b0, tag: signal_pkg::prf_address_t'(n)};
            sc_prf_preload_data <= sc_prf_array[n-1];
            n++;
        end

        @(negedge clk);
        sc_prf_preload_en   <= 1'b0;
        sc_prf_preload_addr <= '0;
        sc_prf_preload_data <= '0;
    endtask
    
    task automatic preload_vc_prf();
        int n = 1;
        
        repeat(vc_prf_array.size()) begin
            @(negedge clk);
            $display("%0d %h",n, vc_prf_array[n-1]);
            vc_prf_preload_en   <= 1'b1;
            vc_prf_preload_addr <= '{vector: 1'b1, tag: signal_pkg::prf_address_t'(n)};
            vc_prf_preload_data <= vc_prf_array[n-1];
            n++;
        end


        @(negedge clk);
        vc_prf_preload_en   <= 1'b0;
        vc_prf_preload_addr <= '0;
        vc_prf_preload_data <= '0;
    endtask

    task automatic preload_imem();
       
        int n = 0;
        
        repeat(instr_array.size()) begin
            @(negedge clk);
            imem_preload_en <= 1'b1;
            imem_preload_request.address <= n;
            imem_preload_request.data    <= instr_array[n];
            imem_preload_request.write_enable <= 1'b1;
            n++;
            
        end
        @(negedge clk);
        imem_preload_en <= 1'b0;
        imem_preload_request <= '0;
    endtask

    task automatic preload_dmem();
       
        int n = 0;
        
        repeat(data_array.size()) begin
            @(negedge clk);
            dmem_preload_en <= 1'b1;
            dmem_preload_request.address <= n;
            dmem_preload_request.data    <= data_array[n];
            dmem_preload_request.write_enable <= 4'b1111;
            n++;
            
        end
        @(negedge clk);
        dmem_preload_en <= 1'b0;
        dmem_preload_request <= '0;
    endtask

    task automatic display_final_prf_state_sc();
        logic match = 1;
        $display("                             FINAL STATE SCALAR PRF");
        for(int i=0; i<32; i+=4) begin
            $display("R%02d: %h (%04d)\t| R%02d: %h (%04d)\t| R%02d: %h (%04d)\t| R%02d: %h (%04d)",
                i,
                $signed(dut.u_core.u_scalar_prf_replica0.regfile[dut.u_core.u_alloc_rename_retire.sc_commit_table[i]]),
                $signed(dut.u_core.u_scalar_prf_replica0.regfile[dut.u_core.u_alloc_rename_retire.sc_commit_table[i]]),
                i+1,
                $signed(dut.u_core.u_scalar_prf_replica0.regfile[dut.u_core.u_alloc_rename_retire.sc_commit_table[i+1]]),
                $signed(dut.u_core.u_scalar_prf_replica0.regfile[dut.u_core.u_alloc_rename_retire.sc_commit_table[i+1]]),
                i+2,
                $signed(dut.u_core.u_scalar_prf_replica0.regfile[dut.u_core.u_alloc_rename_retire.sc_commit_table[i+2]]),
                $signed(dut.u_core.u_scalar_prf_replica0.regfile[dut.u_core.u_alloc_rename_retire.sc_commit_table[i+2]]),
                i+3,
                $signed(dut.u_core.u_scalar_prf_replica0.regfile[dut.u_core.u_alloc_rename_retire.sc_commit_table[i+3]]),
                $signed(dut.u_core.u_scalar_prf_replica0.regfile[dut.u_core.u_alloc_rename_retire.sc_commit_table[i+3]])
            );
        end
        
        for(int i=0; i<32; i++) begin
            match = match && (
                dut.u_core.u_scalar_prf_replica0.regfile[dut.u_core.u_alloc_rename_retire.sc_commit_table[i]] ==
                dut.u_core.u_scalar_prf_replica1.regfile[dut.u_core.u_alloc_rename_retire.sc_commit_table[i]]
                );
        end
        if(match) $display("\nReplicas Match");
        else $display("\nReplicas do not match");
        $display("----------------------------------------------------------------------------------------------------");
    endtask

    task automatic display_final_prf_state_vc();
        $display("                             FINAL STATE VECTOR PRF");
        for(int i=0; i<32; i++) begin
            $display("V%02d:\t%h (%04d)  \t%h (%04d)  \t%h (%04d)  \t%h (%04d) ", 
                    i, 
                    $signed(dut.u_core.u_vector_prf.regfile[dut.u_core.u_alloc_rename_retire.vc_commit_table[i]][0]),
                    $signed(dut.u_core.u_vector_prf.regfile[dut.u_core.u_alloc_rename_retire.vc_commit_table[i]][0]),
                    $signed(dut.u_core.u_vector_prf.regfile[dut.u_core.u_alloc_rename_retire.vc_commit_table[i]][1]),
                    $signed(dut.u_core.u_vector_prf.regfile[dut.u_core.u_alloc_rename_retire.vc_commit_table[i]][1]),
                    $signed(dut.u_core.u_vector_prf.regfile[dut.u_core.u_alloc_rename_retire.vc_commit_table[i]][2]),
                    $signed(dut.u_core.u_vector_prf.regfile[dut.u_core.u_alloc_rename_retire.vc_commit_table[i]][2]),
                    $signed(dut.u_core.u_vector_prf.regfile[dut.u_core.u_alloc_rename_retire.vc_commit_table[i]][3]),
                    $signed(dut.u_core.u_vector_prf.regfile[dut.u_core.u_alloc_rename_retire.vc_commit_table[i]][3])
                );
        end
        $display("----------------------------------------------------------------------------------------------------");
    endtask

    `include "display_tasks_core.sv"
    `include "display_tasks_data.sv"
    `include "display_tasks_ex.sv"
    `include "display_tasks_fe.sv"
    `include "display_tasks_ooo.sv"
    `include "display_tasks_prf.sv"
    `include "display_tasks_rs.sv"
    `include "display_tasks_wb.sv"
    
    /*always @(posedge clk) begin;
        prev_dest_address <= dut.u_core.u_alloc_rename_retire.retire_instr_i.dest_address;
        prev_prf_tag      <= dut.u_core.u_alloc_rename_retire.retire_instr_i.prf_tag;
        prev_retire_sc    <= dut.u_core.u_alloc_rename_retire.retire_instr_i.valid && !dut.u_core.u_alloc_rename_retire.retire_instr_i.prf_tag.vector;
        prev_retire_vc    <= dut.u_core.u_alloc_rename_retire.retire_instr_i.valid && dut.u_core.u_alloc_rename_retire.retire_instr_i.prf_tag.vector;
        prev_we           <= dut.u_core.u_alloc_rename_retire.retire_instr_i.write_to_reg;
        if(prev_retire_sc) begin
        $display("[sc Retire at cycle %04d (%05t ns)](%b)\tR%02d  \ttag: %03d\tval: %h",
            (cycles-1), ($time()-20), prev_we,
            prev_dest_address,
            prev_prf_tag,
            dut.u_core.u_scalar_prf_replica0.regfile[dut.u_core.u_alloc_rename_retire.sc_commit_table[prev_dest_address]]
            
        );
        end
        if(prev_retire_vc) begin
        $display("[vc Retire at cycle %04d (%05t ns)](%b)\tV%02d  \ttag: %03d\tval: %h",
            (cycles-1), ($time()-20), prev_we,
            prev_dest_address, 
            prev_prf_tag,
            dut.u_core.u_vector_prf.regfile[dut.u_core.u_alloc_rename_retire.vc_commit_table[prev_dest_address]]
            
        );
        end
    end*/

    initial begin
        init();
        //preload_sc_prf();
        //preload_vc_prf();
        preload_imem();
        preload_dmem();
        compute = 1'b1;
        cycles = 0;
        
        $display("----------------------------------------------------------------------------------------------------");
        $display("                                                BEGIN TEST");    
        $display("----------------------------------------------------------------------------------------------------");
    

    end

    always @(posedge clk) begin
        #1;
        cycles++;

        //display_stage_valids();

        //display_fetch_states();
        //display_decode_states();

        //display_queue_states();

        //display_arr_states();
        //display_arr_states_sc();
        //display_arr_states_vc();
        //display_commit_table();

        //display_rob_states();

        //display_rs_states_sc();
        //display_rs_states_branch();
        //display_rs_states_muldiv();
        //display_rs_states_vc();
        //display_rs_states_lsu();

        //display_prf_sc();
        //display_prf_vc();
        //display_prf_inout_sc();
        //display_prf_inout_vc();
        //display_prf_inout_br();
        //display_prf_inout_ls();

        //display_muldiv_states();
        //display_branch_states();
        //display_vc_alu_states();
        //display_lsu_inout();

        //display_dmem_inout();
        //display_dmem_val(0);
        //display_dmem_val(1);
        //display_dmem_val(2);
        //display_dmem_controller();

        //display_sc_wb();
        //display_vc_wb();

        //display_commit_states_sc();
        //display_commit_states_vc();

        if(cycles >= 512) begin
            $display("----------------------------------------------------------------------------------------------------");
            $display("                                           RUN COMPLETE"); 
            $display("----------------------------------------------------------------------------------------------------");
            display_final_prf_state_sc();
            display_final_prf_state_vc();
            display_dmem_val(20);
            display_dmem_val(32);
            $finish;
        end
    end
endmodule