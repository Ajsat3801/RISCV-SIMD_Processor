
    task automatic display_muldiv_states();
        $display("[MULDIV] IN:[%b @ %0d - %h %h], ready:[%b %b %b] OUT:[%b @ %0d - %h]",
            dut.u_core.u_scalar_muldiv.sc_ex_request_i.valid,
            dut.u_core.u_scalar_muldiv.sc_ex_request_i.prf_tag,
            dut.u_core.u_scalar_muldiv.sc_ex_request_i.operand_a,
            dut.u_core.u_scalar_muldiv.sc_ex_request_i.operand_b,
            dut.u_core.u_scalar_muldiv_rs.sc_ex_ready_i,
                !(dut.u_core.sc_rd_req[2]),
                !(dut.u_core.sc_ex_req[2]),
            dut.u_core.u_scalar_muldiv.sc_ex_result_o.valid,
            dut.u_core.u_scalar_muldiv.sc_ex_result_o.prf_tag,
            dut.u_core.u_scalar_muldiv.sc_ex_result_o.data
        );
    endtask

    task automatic display_branch_states();
        if(dut.u_core.u_branch.br_ex_request_i.valid || dut.u_core.u_branch.br_ex_result_o.valid)
        $display("[BRANCH] IN:[%b - %b %h %h] CMP:[%b %b %b] Out:[%b %b]",
            dut.u_core.u_branch.br_ex_request_i.valid,
            dut.u_core.u_branch.br_ex_request_i.operation,
            dut.u_core.u_branch.br_ex_request_i.operand_a,
            dut.u_core.u_branch.br_ex_request_i.operand_b,
            dut.u_core.u_branch.a_lt_b,
            dut.u_core.u_branch.a_lt_b_u,
            dut.u_core.u_branch.a_eq_b,
            dut.u_core.u_branch.br_ex_result_o.valid,
            dut.u_core.u_branch.br_ex_result_o.branch_taken
        );
    endtask

    task automatic display_vc_alu_states();
        $display("[VC ALU] IN:[%b @ %0d - %h %h], OUT:[%b @ %0d - %h]",
            dut.u_core.u_vector_alu.vc_ex_request_i.valid,
            dut.u_core.u_vector_alu.vc_ex_request_i.rob_id,
            dut.u_core.u_vector_alu.vc_ex_request_i.operand_a,
            dut.u_core.u_vector_alu.vc_ex_request_i.operand_b,
            dut.u_core.u_vector_alu.vc_ex_result_o.valid,
            dut.u_core.u_vector_alu.vc_ex_result_o.rob_id,
            dut.u_core.u_vector_alu.vc_ex_result_o.data
        );
    endtask

    task automatic display_lsu_inout();
        $display("[LSU] in[%b %h %h @ %0d], out[%b %h @ %0d]",
            dut.u_core.u_lsu.lsu_request_i.valid,
            dut.u_core.u_lsu.lsu_request_i.operand_a,
            dut.u_core.u_lsu.lsu_request_i.operand_b,
            dut.u_core.u_lsu.lsu_request_i.prf_tag,
            dut.u_core.u_lsu.lsu_output_o.valid,
            dut.u_core.u_lsu.lsu_output_o.mem_addr,
            dut.u_core.u_lsu.lsu_output_o.prf_tag
        );
    endtask