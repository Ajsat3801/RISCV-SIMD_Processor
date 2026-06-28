
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
        $display("[BRANCH] IN:[%b - %s %h %h] CMP:[%b %b %b] Out:[%b %b]",
            dut.u_core.u_branch.br_ex_request_i.valid,
            dut.u_core.u_branch.br_ex_request_i.operation.br.name(),
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
    if(dut.u_core.u_lsu.lsu_request_i.valid || dut.u_core.u_lsu.lsu_output_o.valid || dut.u_core.u_lsu.retire_instr_i.valid)
        $display("[LSU] IN: (%b - %b) SC:[%0d %0d %0d @ %0d & %0d] VC:[(%b) %0d %0d %0d %0d] ret:[%b %0d] buf:[%0d %0d %0d %0d] out[%b (%b) @ %0d - %0d %0d %0d %0d] %b",
            dut.u_core.u_lsu.lsu_request_i.valid,
            dut.u_core.u_lsu.in.is_store,

            $signed(dut.u_core.u_lsu.lsu_request_i.operand_a),
            $signed(dut.u_core.u_lsu.lsu_request_i.operand_b),
            $signed(dut.u_core.u_lsu.sc_store_data_i),
            dut.u_core.u_lsu.lsu_request_i.prf_tag,
            dut.u_core.u_lsu.lsu_request_i.rob_id,

            dut.u_core.u_lsu.lsu_request_i.prf_tag.vector,  
            $signed(dut.u_core.u_lsu.vc_lsu_ex_request_i.store_data[0]),
            $signed(dut.u_core.u_lsu.vc_lsu_ex_request_i.store_data[1]),
            $signed(dut.u_core.u_lsu.vc_lsu_ex_request_i.store_data[2]),
            $signed(dut.u_core.u_lsu.vc_lsu_ex_request_i.store_data[3]),

            dut.u_core.u_lsu.retire_instr_i.valid,
            dut.u_core.u_lsu.retire_instr_i.rob_id,

            dut.u_core.u_lsu.store_buffer[0].rob_id,
            dut.u_core.u_lsu.store_buffer[1].rob_id,
            dut.u_core.u_lsu.store_buffer[2].rob_id,
            dut.u_core.u_lsu.store_buffer[3].rob_id,
            
            dut.u_core.u_lsu.lsu_output_o.valid,
            dut.u_core.u_lsu.lsu_output_o.is_store,
            dut.u_core.u_lsu.lsu_output_o.mem_addr,
            $signed(dut.u_core.u_lsu.lsu_output_o.data[0]),
            $signed(dut.u_core.u_lsu.lsu_output_o.data[1]),
            $signed(dut.u_core.u_lsu.lsu_output_o.data[2]),
            $signed(dut.u_core.u_lsu.lsu_output_o.data[3]),
            dut.u_core.u_lsu.store_out
        );
    endtask