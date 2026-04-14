/*Extremely basic functional testing
 * Primarily to check if all modules are compiling and a very basic program runs
*/

module core_tb;
    logic clk, reset_n;
    logic fetch_valid, pre_load;
    instr_pkg::data_t raw_instr, pc, pre_load_data;
    instr_pkg::prf_tag_t pre_load_addr;
    logic ready;

    core dut(
        .clk_i(clk),
        .reset_ni(reset_n),
        .raw_instr_i(raw_instr),
        .pc_i(pc),
        .fetch_valid_i(fetch_valid),
        .pre_load_i(pre_load),
        .pre_load_addr_i(pre_load_addr),
        .pre_load_data_i(pre_load_data),
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
        pre_load = 1'b0;
        raw_instr = '0;
        pc = '0;
        pre_load_addr = '0;
        pre_load_data = '0;
    end

    initial begin

        repeat (3) @(posedge clk);
        reset_n = 1'b1;
        repeat (3) @(posedge clk)

        #10;
        pre_load = 1'b1;
        pre_load_addr = 7'b0000001;
        pre_load_data = 7'b0000001;

        #20;
        pre_load = 1'b1;
        pre_load_addr = 7'b0000010;
        pre_load_data = 7'b0000010;

        #20;
        pre_load = 1'b0;
        pre_load_addr = '0;
        pre_load_data = '0;

        fetch_valid = 1'b1;
        // ADD R3 R1 R2
        raw_instr = 32'b00000000001000001000000110110011;
        
        #20;
        fetch_valid = 1'b1;
        // SUM R4 R1 R2
        raw_instr = 32'b01100000001000001000001000110011;

        #20
        fetch_valid = 1'b0;

    end

    task automatic display_final_state();
        $display("[FINAL] addr1:%h, addr2:%h, addr3:%h, addr4:%h",
                dut.u_scalar_prf.regfile[1], 
                dut.u_scalar_prf.regfile[2], 
                dut.u_scalar_prf.regfile[32], 
                dut.u_scalar_prf.regfile[33]
        );
    endtask

    task automatic display_stage_valids();             
        $display("[CORE] fetch=%h, decode=%h, queue=%h, alloc=%h, operand=%h, rs=%h %h, alu=%h %h, wb=%h, retire=%h",
                dut.u_decoder.fetch_valid_i,
                dut.u_decoder.decoded_instr_o.valid, 
                dut.u_instruction_bus.valid,
                dut.u_scalar_alloc_bus.valid,
                dut.u_scalar_operand_bus.prf_valid,
                dut.u_scalar_alu0.alu_input_i.valid, dut.u_scalar_alu1.alu_input_i.valid,
                dut.u_scalar_writeback.ex_result_i[0].valid, dut.u_scalar_writeback.ex_result_i[1].valid,
                dut.u_scalar_writeback.scalar_data_bus_o.valid,
                dut.u_retirement_bus.valid
        );
    endtask

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

    task automatic display_rs_states();
        $display("[RS] in_valid:%h, slot:%h ready:%h %h, out: %d %d %b %b",
                dut.u_scalar_alu_rs.rs_input_i.rs_entry.occupied,
                dut.u_scalar_alu_rs.rs_input_i.rs_slot,
                dut.u_scalar_alu_rs.rs_input_i.rs_entry.operand_a_ready,
                dut.u_scalar_alu_rs.rs_input_i.rs_entry.operand_b_ready,
                dut.u_scalar_alu_rs.dispatch1_o.prf_tag,
                dut.u_scalar_alu_rs.dispatch2_o.prf_tag,
                dut.u_scalar_alu_rs.dispatch1_o.valid,
                dut.u_scalar_alu_rs.dispatch2_o.valid
        );
    endtask

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

    task automatic display_prf_states_wb();
        $display("[PRF WB] in_valid:%h, tag: %d, data:%h",
                dut.u_scalar_prf.writeback_instr_i.valid,
                dut.u_scalar_prf.writeback_instr_i.prf_tag,
                dut.u_scalar_prf.writeback_instr_i.data
        );
    endtask

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
        /*$display("[ARR] \nRAT:%p \nCommit:%p",
                dut.u_scalar_arr.reg_alloc_table,
                dut.u_scalar_arr.commit_table
        );*/
    endtask

    task automatic display_alu_states();
        $display("[ALU0] out: %b %d %h",
            dut.u_scalar_alu0.alu_result_o.valid,
            dut.u_scalar_alu0.alu_result_o.prf_tag,
            dut.u_scalar_alu0.alu_result_o.data
        );
        $display("[ALU1] out: %b %d %h",
            dut.u_scalar_alu1.alu_result_o.valid,
            dut.u_scalar_alu1.alu_result_o.prf_tag,
            dut.u_scalar_alu1.alu_result_o.data
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

    task automatic display_rob_states();
        $display("[ROB] in: %b %d",
                dut.u_reorder_buffer.scalar_wb_i.valid,
                dut.u_reorder_buffer.scalar_wb_i.rob_id,
        );
    endtask

    always @(posedge clk) begin
        $display("Time: %0t",$time());
        display_final_state();
        //display_stage_valids();
        //display_decode_states();
        //display_iq_states();
        //display_rs_states();
        //display_alu_states();
        //display_wb_states();
        //display_prf_states_alloc();
        //display_prf_states_wb();
        //display_arr_states();
        //display_rob_states();
    end

    initial begin
        #500;
        $finish;
    end

endmodule