
    task automatic display_rs_states_sc();
        $display("[SC RS] in for %0d [%b @ %0d %0d (%0d-%h %0d-%h)] ready:[%b %b] data_bus:[%b %0d] out:[%b %0d | %b %0d]",
                dut.u_core.u_scalar_alu_rs.rs_request_i.chip_select,
                dut.u_core.u_scalar_alu_rs.rs_request_i.valid,
                dut.u_core.u_scalar_alu_rs.rs_request_i.rs_slot_id,
                dut.u_core.u_scalar_alu_rs.rs_request_i.rs_entry.prf_tag,
                dut.u_core.u_scalar_alu_rs.rs_request_i.rs_entry.operand_a_tag,
                dut.u_core.u_scalar_alu_rs.rs_request_i.rs_entry.operand_a_ready,
                dut.u_core.u_scalar_alu_rs.rs_request_i.rs_entry.operand_b_tag,
                dut.u_core.u_scalar_alu_rs.rs_request_i.rs_entry.operand_b_ready,
                dut.u_core.u_scalar_alu_rs.sc_ex0_ready_i,
                dut.u_core.u_scalar_alu_rs.sc_ex1_ready_i,
                dut.u_core.u_scalar_alu_rs.sc_data_bus_i.valid,
                dut.u_core.u_scalar_alu_rs.sc_data_bus_i.prf_tag,
                dut.u_core.u_scalar_alu_rs.sc_rd_req0_o.valid,
                dut.u_core.u_scalar_alu_rs.sc_rd_req0_o.prf_tag,
                dut.u_core.u_scalar_alu_rs.sc_rd_req1_o.valid,
                dut.u_core.u_scalar_alu_rs.sc_rd_req1_o.prf_tag  
        );
    endtask

    task automatic display_rs_states_muldiv();
        $display("[MULDIV RS] in for %0d [%b @ %0d %0d (%0d-%h %0d-%h)] ready:[%b %b %b - %b] data_bus:[%b %0d] out:[%b %0d]",
                dut.u_core.u_scalar_muldiv_rs.rs_request_i.chip_select,
                dut.u_core.u_scalar_muldiv_rs.rs_request_i.valid,
                dut.u_core.u_scalar_muldiv_rs.rs_request_i.rs_slot_id,
                dut.u_core.u_scalar_muldiv_rs.rs_request_i.rs_entry.prf_tag,
                dut.u_core.u_scalar_muldiv_rs.rs_request_i.rs_entry.operand_a_tag,
                dut.u_core.u_scalar_muldiv_rs.rs_request_i.rs_entry.operand_a_ready,
                dut.u_core.u_scalar_muldiv_rs.rs_request_i.rs_entry.operand_b_tag,
                dut.u_core.u_scalar_muldiv_rs.rs_request_i.rs_entry.operand_b_ready,
                dut.u_core.sc_ex_ready[2],
                !(dut.u_core.sc_rd_req[2].valid),
                !(dut.u_core.sc_ex_req[2].valid),
                dut.u_core.u_scalar_muldiv_rs.sc_ex_ready_i,
                dut.u_core.u_scalar_muldiv_rs.sc_data_bus_i.valid,
                dut.u_core.u_scalar_muldiv_rs.sc_data_bus_i.prf_tag,
                dut.u_core.u_scalar_muldiv_rs.sc_rd_req_o.valid,
                dut.u_core.u_scalar_muldiv_rs.sc_rd_req_o.prf_tag,
        );
    endtask

    task automatic display_rs_states_branch();

        $display("[BRANCH RS] in for %0d [%b @ %0d %0d (%0d-%h %0d-%h)] ready:%b data_bus:[%b %0d] out:[%b %0d]",
                dut.u_core.u_branch_rs.rs_request_i.chip_select,
                dut.u_core.u_branch_rs.rs_request_i.valid,
                dut.u_core.u_branch_rs.rs_request_i.rs_slot_id,
                dut.u_core.u_branch_rs.rs_request_i.rs_entry.prf_tag,
                dut.u_core.u_branch_rs.rs_request_i.rs_entry.operand_a_tag,
                dut.u_core.u_branch_rs.rs_request_i.rs_entry.operand_a_ready,
                dut.u_core.u_branch_rs.rs_request_i.rs_entry.operand_b_tag,
                dut.u_core.u_branch_rs.rs_request_i.rs_entry.operand_b_ready,
                dut.u_core.u_branch_rs.sc_ex_ready_i,
                dut.u_core.u_branch_rs.sc_data_bus_i.valid,
                dut.u_core.u_branch_rs.sc_data_bus_i.prf_tag,
                dut.u_core.u_branch_rs.sc_rd_req_o.valid,
                dut.u_core.u_branch_rs.sc_rd_req_o.prf_tag,
        );
    endtask

    task automatic display_rs_states_vc();
        $display("[VC RS] in:[%b %0d @ %0d (%h %h)] ready:%b out:[%0d %b]",
                dut.u_core.u_vector_alu_rs.rs_request_i.rs_entry.occupied,
                dut.u_core.u_vector_alu_rs.rs_request_i.rs_entry.prf_tag,
                dut.u_core.u_vector_alu_rs.rs_request_i.rs_slot_id,
                dut.u_core.u_vector_alu_rs.rs_request_i.rs_entry.operand_a_ready,
                dut.u_core.u_vector_alu_rs.rs_request_i.rs_entry.operand_b_ready,
                dut.u_core.u_vector_alu_rs.vc_ex_ready_i,
                dut.u_core.u_vector_alu_rs.vc_read_request_o.prf_tag,
                dut.u_core.u_vector_alu_rs.vc_read_request_o.valid
        );
    endtask

    task automatic display_rs_states_lsu();
    if(dut.u_core.u_lsu_rs.ls_read_request_o.valid || dut.u_core.u_lsu_rs.instr_valid)
        $display("[LSU RS] in:[%b @ %0d %0d (%0d %h | %0d %h) imm(%b %b)] ready:%b out:[%b %0d imm(%b %b)]",
                dut.u_core.u_lsu_rs.rs_request_i.valid,
                dut.u_core.u_lsu_rs.rs_request_i.rs_slot_id,
                dut.u_core.u_lsu_rs.rs_request_i.rs_entry.prf_tag,
                dut.u_core.u_lsu_rs.rs_request_i.rs_entry.operand_a_tag,
                dut.u_core.u_lsu_rs.rs_request_i.rs_entry.operand_a_ready,
                dut.u_core.u_lsu_rs.rs_request_i.rs_entry.operand_b_tag,
                dut.u_core.u_lsu_rs.rs_request_i.rs_entry.operand_b_ready,
                dut.u_core.u_lsu_rs.rs_request_i.rs_entry.read_src2,
                dut.u_core.u_lsu_rs.rs_request_i.rs_entry.imm,
                dut.u_core.u_lsu_rs.lsu_ready_i,
                dut.u_core.u_lsu_rs.ls_read_request_o.valid,
                dut.u_core.u_lsu_rs.ls_read_request_o.prf_tag,
                dut.u_core.u_lsu_rs.ls_read_request_o.read_src2,
                dut.u_core.u_lsu_rs.ls_read_request_o.imm
        );
    endtask