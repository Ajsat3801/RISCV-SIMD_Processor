/*Extremely basic functional testing
 * Primarily to check if all modules are compiling and a very basic program runs
 TODO: Retirement seems to be not working. 
*/

module core_tb;
    logic clk, reset_n;
    logic fetch_valid, sc_pre_load, vc_pre_load;
    instr_pkg::data_t raw_instr, pc, sc_pre_load_data;
    instr_pkg::vector_data_t vc_pre_load_data;
    instr_pkg::prf_tag_t sc_pre_load_addr, vc_pre_load_addr;
    logic ready;

    int cycles;

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

        reset_n = 1'b0;
        fetch_valid = 1'b0;
        sc_pre_load = 1'b0;
        raw_instr = '0;
        pc = '0;
        sc_pre_load_addr = '0;
        sc_pre_load_data = '0;
        cycles = 0;
    end

    initial begin

        repeat (3) @(posedge clk);
        reset_n = 1'b1;
        repeat (3) @(posedge clk)

        #10;
        sc_pre_load = 1'b1;
        sc_pre_load_addr = 7'b0000001;
        sc_pre_load_data = 7'b0000001;
        
        vc_pre_load = 1'b1;
        vc_pre_load_addr = 7'b1000001;
        vc_pre_load_data = {4{32'd1}};

        #20;
        sc_pre_load = 1'b1;
        sc_pre_load_addr = 7'b0000010;
        sc_pre_load_data = 7'b0000010;
        
        vc_pre_load = 1'b1;
        vc_pre_load_addr = 7'b1000010;
        vc_pre_load_data = {4{32'd2}};

        #20;
        sc_pre_load = 1'b0;
        sc_pre_load_addr = '0;
        sc_pre_load_data = '0;

        vc_pre_load = 1'b0;
        vc_pre_load_addr = '0;
        vc_pre_load_data = '0;

        cycles = 0;
        $display("---------------------------------------------------------------------------------");
        $display("                                    BEGIN TEST");
        $display("---------------------------------------------------------------------------------");

        fetch_valid = 1'b1;
        // ADD R3 R1 R2
        raw_instr = 32'b00000000001000001000000110110011;
        
        #20;
        // SUB R4 R2 R1
        raw_instr = 32'b01100000000100010000001000110011;

        #20
        // ADD R5 R3 R4
        raw_instr = 32'b00000000001100100000001010110011;

        #20
        // MUL R6 R2 R5
        raw_instr = 32'b00000010010100010000001100110011;

        #20
        // DIV R7 R6 R5 
        raw_instr = 32'b00000010010100110101001110110011;

        #20
        // VADD.VV R3 R1 R2
        raw_instr = 32'b00000000001000001000000111010111;

        #20
        fetch_valid = 1'b0;

    end

    task automatic display_final_state_sc();
        $display("[FINAL] R1:%h, R2:%h, R3:%h, R4:%h, R5:%h R6: %h, R7:%h",
                dut.u_scalar_prf.regfile[1], 
                dut.u_scalar_prf.regfile[2], 
                dut.u_scalar_prf.regfile[32], 
                dut.u_scalar_prf.regfile[33],
                dut.u_scalar_prf.regfile[34],
                dut.u_scalar_prf.regfile[35],
                dut.u_scalar_prf.regfile[36]
        );
    endtask
    task automatic display_final_state_vc();
        $display("[FINAL] R1:%h, R2:%h, R3:%h, R4:%h, R5:%h R6: %h, R7:%h",
                dut.u_vector_prf.regfile[1], 
                dut.u_vector_prf.regfile[2], 
                dut.u_vector_prf.regfile[32], 
                dut.u_vector_prf.regfile[33],
                dut.u_vector_prf.regfile[34],
                dut.u_vector_prf.regfile[35],
                dut.u_vector_prf.regfile[36]
        );
    endtask
    task automatic display_preload_state();
        $display("[PRE-LOAD] Vector preload: %b %d %h",
            dut.u_vector_prf.vc_wb_instr_i.valid,
            dut.u_vector_prf.vc_wb_instr_i.prf_tag,
            dut.u_vector_prf.vc_wb_instr_i.data,
        );
    endtask
    task automatic display_stage_valids();             
        $display("[SC CORE] fetch=%h, decode=%h, queue=%h, alloc=%h, load=%h, rs=%h %h %h, ex=%h %h %h, wb=%h, retire=%h",
                dut.u_decode.fetch_valid_i,
                dut.u_decode.decoded_instr_o.valid, 
                dut.u_instr_q.dispatched_instr_o.valid,
                dut.u_scalar_arr.alloc_instr_o.valid,
                dut.u_sc_request_bus.rs_entry.occupied,
                dut.u_scalar_alu_rs.sc_ex0_request_o.valid, dut.u_scalar_alu_rs.sc_ex1_request_o.valid,
                dut.u_scalar_muldiv_rs.sc_ex_request_o.valid,
                dut.u_scalar_alu0.sc_ex_result_o.valid, dut.u_scalar_alu1.sc_ex_result_o.valid,
                dut.u_scalar_muldiv.sc_ex_result_o.valid,
                dut.u_scalar_writeback.data_bus_o.valid,
                dut.u_reorder_buffer.retire_instr_o.valid
        );
    endtask
    task automatic display_stage_valids_vc();             
        $display("[VC CORE] fetch=%h, decode=%h, queue=%h, alloc=%h, load=%h, rs=%h, ex=%h, wb=%h, retire=%b %b",
                dut.u_decode.fetch_valid_i, //fetch
                dut.u_decode.decoded_instr_o.valid, //decode
                dut.u_instr_q.dispatched_instr_o.valid, //queue
                dut.u_vector_arr.alloc_instr_o.valid, //alloc
                dut.u_vc_request_bus.valid, //load
                dut.u_vector_alu_rs.vc_read_request_o.valid, // rs
                dut.u_vector_alu.vc_ex_result_o.valid, // ex
                dut.u_vector_writeback.data_bus_o.valid, //wb
                dut.u_reorder_buffer.retire_instr_o.valid, //retire
                dut.u_reorder_buffer.retire_instr_o.prf_tag
        );
    endtask
    task automatic display_muldiv_rs_states();
        $display("[MULDIV RS] in:%b @ %h (%h %h), ex: %b %b state: %h data_in: %d %b out: %d %b",
                dut.u_scalar_muldiv_rs.sc_rs_request_i.rs_entry.occupied,
                dut.u_scalar_muldiv_rs.sc_rs_request_i.rs_slot,
                dut.u_scalar_muldiv_rs.sc_rs_request_i.rs_entry.operand_a_ready,
                dut.u_scalar_muldiv_rs.sc_rs_request_i.rs_entry.operand_b_ready,
                dut.u_scalar_muldiv.sc_ex_ready_o,
                dut.u_scalar_muldiv_rs.sc_ex_ready_i,
                dut.u_scalar_muldiv.state,
                dut.u_scalar_muldiv_rs.sc_data_bus_i.prf_tag,
                dut.u_scalar_muldiv_rs.sc_data_bus_i.valid,
                dut.u_scalar_muldiv_rs.sc_ex_request_o.prf_tag,
                dut.u_scalar_muldiv_rs.sc_ex_request_o.valid
                
        );
    endtask
    task automatic display_muldiv_states();
        $display("[MULDIV] in:%b @ %0d %0d (%h %h), state: %h out: %b %0d %0d %h ready:%b",
                
                dut.u_scalar_muldiv.sc_ex_request_i.valid,
                dut.u_scalar_muldiv.sc_ex_request_i.prf_tag,
                dut.u_scalar_muldiv.sc_ex_request_i.rob_id,
                dut.u_scalar_muldiv.sc_ex_request_i.operand_a,
                dut.u_scalar_muldiv.sc_ex_request_i.operand_b,
                dut.u_scalar_muldiv.state,
                dut.u_scalar_muldiv.sc_ex_result_o.valid,
                dut.u_scalar_muldiv.sc_ex_result_o.prf_tag,
                dut.u_scalar_muldiv.sc_ex_request_i.rob_id,
                dut.u_scalar_muldiv.sc_ex_result_o.data,
                dut.u_scalar_muldiv.sc_ex_ready_o
                
        );
        $display("[MUL] in:%b (%h %h %b), state: %h out: %b",
                
                dut.u_scalar_muldiv.u_multiplier.valid_i,
                dut.u_scalar_muldiv.u_multiplier.multiplicand_i,
                dut.u_scalar_muldiv.u_multiplier.multiplier_i,
                dut.u_scalar_muldiv.u_multiplier.unsigned_multiplicand,
                dut.u_scalar_muldiv.u_multiplier.state,
                //dut.u_scalar_muldiv.u_multiplier.result_o,
                dut.u_scalar_muldiv.u_multiplier.valid_o,
                
        );
        $display("[DIV] in:%b (%h %h %b), count: %h state: %h out: %b",
                
                dut.u_scalar_muldiv.u_divider.valid_i,
                dut.u_scalar_muldiv.u_divider.dividend_i,
                dut.u_scalar_muldiv.u_divider.divisor_i,
                dut.u_scalar_muldiv.u_divider.unsigned_div,
                dut.u_scalar_muldiv.u_divider.count,
                dut.u_scalar_muldiv.u_divider.state,
                //dut.u_scalar_muldiv.u_divider.result_o,
                dut.u_scalar_muldiv.u_divider.valid_o,
                
        );
        
    endtask
    task automatic display_div_states();
        $display("[DIV] in:%b (%h %h %b), count: %h state: %h",
                
                dut.u_scalar_muldiv.u_divider.valid_i,
                dut.u_scalar_muldiv.u_divider.dividend_i,
                dut.u_scalar_muldiv.u_divider.divisor_i,
                dut.u_scalar_muldiv.u_divider.unsigned_div,
                dut.u_scalar_muldiv.u_divider.count,
                dut.u_scalar_muldiv.u_divider.state,
                
        ); 
        $display("out(val:%b)  : %b", dut.u_scalar_muldiv.u_divider.valid_o,dut.u_scalar_muldiv.u_divider.result_o,);
        $display("result      : %b", dut.u_scalar_muldiv.u_divider.result);
        $display("result_next : %b", dut.u_scalar_muldiv.u_divider.result_next);
    endtask
    task automatic display_div_intermediates();
        $display("result    : %b %b", 
            dut.u_scalar_muldiv.u_divider.result[63:32],
            dut.u_scalar_muldiv.u_divider.result[31:0]
        );
        $display("dbg_shft  : %b %b", 
            dut.u_scalar_muldiv.u_divider.dbg_shft[63:32],
            dut.u_scalar_muldiv.u_divider.dbg_shft[31:0]
        );
        $display("m         : %b", dut.u_scalar_muldiv.u_divider.m);
        $display("dbg_add   : %b %b", 
            dut.u_scalar_muldiv.u_divider.dbg_add[63:32],
            dut.u_scalar_muldiv.u_divider.dbg_add[31:0]
        );
        $display("next      : %b %b", 
            dut.u_scalar_muldiv.u_divider.result_next[63:32],
            dut.u_scalar_muldiv.u_divider.result_next[31:0]
        );
    endtask
/*
    task automatic display_decode_states();
        $display("[DECODE] opcode:%h, cs:%h",
                dut.u_decoder.opcode,
                dut.u_decoder.decoded_instr_o.chip_select
        );
    endtask
    task automatic display_iq_states();
        $display("[IQ] in_valid:%h, rs:%b %h %h, cs:%h head:%h out:%b %d",
                dut.u_instr_q.decoded_instr_i.valid,

                dut.u_instr_q.reset_wb_n,
                dut.u_instr_q.next_rs_slot[0],
                dut.u_instr_q.rs_index,

                dut.u_instr_q.cs,
                dut.u_instr_q.head,
                dut.u_instr_q.alloc_instr_o.valid,
                dut.u_instr_q.alloc_instr_o.rs_slot_id
        );
    endtask
*/
    task automatic display_rs_states();
        $display("[RS] in:[%b @ %0d (%h %h)] ready:%b %b out:[%0d %0d %b %b]",
                dut.u_scalar_alu_rs.sc_rs_request_i.rs_entry.occupied,
                dut.u_scalar_alu_rs.sc_rs_request_i.rs_slot,
                dut.u_scalar_alu_rs.sc_rs_request_i.rs_entry.operand_a_ready,
                dut.u_scalar_alu_rs.sc_rs_request_i.rs_entry.operand_b_ready,
                dut.u_scalar_alu_rs.sc_ex0_ready_i,
                dut.u_scalar_alu_rs.sc_ex1_ready_i,
                dut.u_scalar_alu_rs.sc_ex0_request_o.prf_tag,
                dut.u_scalar_alu_rs.sc_ex1_request_o.prf_tag,
                dut.u_scalar_alu_rs.sc_ex0_request_o.valid,
                dut.u_scalar_alu_rs.sc_ex1_request_o.valid
        );
    endtask
/*
    task automatic display_prf_states_alloc();
        $display("[PRF_ALLOC] in_valid:%h %h, alloc: %d %d ",
                dut.u_scalar_prf.allocated_instr_i.valid,
                dut.u_scalar_prf.writeback_instr_i.valid,
                dut.u_scalar_prf.allocated_instr_i.prf_tag,
                dut.u_scalar_prf.allocated_instr_i.rs_slot
        );
        $display("Out valid: %b slot:%h ready:%h %h rob:%d",
                dut.u_scalar_prf.instr_o.prf_valid,
                dut.u_scalar_prf.instr_o.rs_slot,
                dut.u_scalar_prf.instr_o.operand_a_ready,
                dut.u_scalar_prf.instr_o.operand_b_ready,
                dut.u_scalar_prf.instr_o.rob_id
        );
    endtask
*/
    task automatic display_prf_states_wb();
        $display("[PRF WB] in [%b %h @ %b]",
                dut.u_vector_prf.vc_wb_instr_i.valid,
                dut.u_vector_prf.vc_wb_instr_i.data,
                dut.u_vector_prf.vc_wb_instr_i.prf_tag
        );
    endtask
    task automatic display_wb_states_vc();
        $display("[WB] in[%b %h @ %d %d] [%b %b] out[%b %h @ %d %d]",
                dut.u_vector_writeback.ex_result_i[0].valid,
                dut.u_vector_writeback.ex_result_i[0].data,
                dut.u_vector_writeback.ex_result_i[0].rob_id,
                dut.u_vector_writeback.ex_result_i[0].prf_tag,
                dut.u_vector_writeback.full,
                dut.u_vector_writeback.empty,
                dut.u_vector_writeback.data_bus_o.valid,
                dut.u_vector_writeback.data_bus_o.data,
                dut.u_vector_writeback.data_bus_o.rob_id,
                dut.u_vector_writeback.data_bus_o.prf_tag
        );
    endtask
    task automatic display_wb_states_sc();
        $display("[WB] in[%b %h @ %d %d] in[%b %h @ %d %d] in[%b %h @ %d %d] \n[%b %b] out[%b %h @ %d %d]",
                dut.u_scalar_writeback.ex_result_i[0].valid,
                dut.u_scalar_writeback.ex_result_i[0].data,
                dut.u_scalar_writeback.ex_result_i[0].rob_id,
                dut.u_scalar_writeback.ex_result_i[0].prf_tag,
                dut.u_scalar_writeback.ex_result_i[1].valid,
                dut.u_scalar_writeback.ex_result_i[1].data,
                dut.u_scalar_writeback.ex_result_i[1].rob_id,
                dut.u_scalar_writeback.ex_result_i[1].prf_tag,
                dut.u_scalar_writeback.ex_result_i[2].valid,
                dut.u_scalar_writeback.ex_result_i[2].data,
                dut.u_scalar_writeback.ex_result_i[2].rob_id,
                dut.u_scalar_writeback.ex_result_i[2].prf_tag,
                dut.u_scalar_writeback.full,
                dut.u_scalar_writeback.empty,
                dut.u_scalar_writeback.data_bus_o.valid,
                dut.u_scalar_writeback.data_bus_o.data,
                dut.u_scalar_writeback.data_bus_o.rob_id,
                dut.u_scalar_writeback.data_bus_o.prf_tag
        );
    endtask
/*
    task automatic display_arr_states();
        $display("[ARR] retirement: %b %d %d %b",
                dut.u_scalar_arr.retire_instr_i.valid,
                dut.u_scalar_arr.retire_instr_i.dest_address,
                dut.u_scalar_arr.retire_instr_i.prf_tag,
                dut.u_scalar_arr.retire_instr_i.write_to_reg
        );
        $write("RAT   :");
        foreach (dut.u_scalar_arr.reg_alloc_table[i]) 
            $write("%0d ", dut.u_scalar_arr.reg_alloc_table[i].tag);
        $write("\n");
        $write("Commit:");
        foreach (dut.u_scalar_arr.commit_table[i]) 
            $write("%0d ", dut.u_scalar_arr.commit_table[i].tag);
        $write("\n");
        $display("[ARR] \nRAT:%p \nCommit:%p",
                dut.u_scalar_arr.reg_alloc_table,
                dut.u_scalar_arr.commit_table
        );
    endtask

    task automatic display_alu_states();
        $display("[ALU0] out: %b %d %h",
            dut.u_sc_alu0.alu_result_o.valid,
            dut.u_sc_alu0.alu_result_o.prf_tag,
            dut.u_sc_alu0.alu_result_o.data
        );
        $display("[ALU1] out: %b %d %h",
            dut.u_sc_alu1.alu_result_o.valid,
            dut.u_sc_alu1.alu_result_o.prf_tag,
            dut.u_sc_alu1.alu_result_o.data
        );
    endtask

    task automatic display_wb_states();
        $write("[WB] in ");
        foreach (dut.u_scalar_writeback.ex_result_i[i])
            $write("[%d %d %d %h] ",
                    dut.u_scalar_writeback.ex_result_i[i].valid,
                    dut.u_scalar_writeback.ex_result_i[i].prf_tag,
                    dut.u_scalar_writeback.ex_result_i[i].rob_id,
                    dut.u_scalar_writeback.ex_result_i[i].data
            );
        $write("\nBranch FIFO heads ");
        foreach (dut.u_scalar_writeback.fifo_heads[i])
            $write("[%d %d %h] ",
                    dut.u_scalar_writeback.fifo_heads[i].valid,
                    dut.u_scalar_writeback.fifo_heads[i].prf_tag,
                    dut.u_scalar_writeback.fifo_heads[i].data
            );
        $display("\nout: %b %d %d %h",
            dut.u_scalar_writeback.scalar_data_bus_o.valid,
            dut.u_scalar_writeback.scalar_data_bus_o.prf_tag,
            dut.u_scalar_writeback.scalar_data_bus_o.rob_id,
            dut.u_scalar_writeback.scalar_data_bus_o.data
        );
    endtask
*/
    task automatic display_rob_states();
        $display("[ROB] in[%b %d @ %d] retire[%b %d] ",
                dut.u_reorder_buffer.sc_data_bus_i.valid,
                dut.u_reorder_buffer.sc_data_bus_i.prf_tag,
                dut.u_reorder_buffer.sc_data_bus_i.rob_id,
                dut.u_reorder_buffer.retire_instr_o.valid,
                dut.u_reorder_buffer.retire_instr_o.prf_tag
        );
    endtask
    task automatic display_commit_states();
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
    task automatic display_commit_table();
        $display("[SPEC] R1:%d R2:%d R3:%d R4:%d R5:%d R6:%d R7:%d",
            dut.u_scalar_arr.reg_alloc_table[1],
            dut.u_scalar_arr.reg_alloc_table[2],
            dut.u_scalar_arr.reg_alloc_table[3],
            dut.u_scalar_arr.reg_alloc_table[4],
            dut.u_scalar_arr.reg_alloc_table[5],
            dut.u_scalar_arr.reg_alloc_table[6],
            dut.u_scalar_arr.reg_alloc_table[7]
        );
        $display("[COMMIT] R1:%d R2:%d R3:%d R4:%d R5:%d R6:%d R7:%d",
            dut.u_scalar_arr.commit_table[1],
            dut.u_scalar_arr.commit_table[2],
            dut.u_scalar_arr.commit_table[3],
            dut.u_scalar_arr.commit_table[4],
            dut.u_scalar_arr.commit_table[5],
            dut.u_scalar_arr.commit_table[6],
            dut.u_scalar_arr.commit_table[7]
        );
    endtask
    always @(posedge clk) begin
        cycles++;
        //if(dut.u_scalar_muldiv.u_divider.state == 1) begin

        $display("Time: %0t, cycle: %0d",$time(), cycles);
        //display_commit_table();
        //display_commit_states();
        //display_final_state_sc();
        //display_final_state_vc();
        //display_preload_state();
        //display_stage_valids();
        //display_stage_valids_vc();
        //display_muldiv_rs_states();
        //display_muldiv_states();
        //display_div_states();
        //display_div_intermediates();
        //display_decode_states();
        //display_iq_states();
        //display_rs_states();
        //display_alu_states();
        //display_wb_states_vc();
        //display_wb_states_sc();
        //display_prf_states_alloc();
        //display_prf_states_wb();
        //display_arr_states();
        display_rob_states();
        //end

        if(cycles >= 80) $finish;
    end

endmodule