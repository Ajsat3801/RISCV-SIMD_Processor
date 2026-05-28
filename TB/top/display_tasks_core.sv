task automatic display_stage_valids();             
        $display("[SC CORE] fetch=%h, decode=%h, queue=%h %0d, alloc=%h %h @ %0d, rs=%h %h %h %h %h %h, ex=%h %h %h %h %h %h, wb=%b %0d|%b %0d, retire=%h (%0d)",
                dut.u_core.u_decode.fetch_valid_i,

                dut.u_core.u_decode.decoded_instr_o.valid, 

                dut.u_core.u_instr_q.dispatched_instr_o.valid,
                dut.u_core.u_instr_q.dispatched_instr_o.dest_address,

                dut.u_core.u_alloc_rename_retire.alloc_instr_o.sc_valid,
                dut.u_core.u_alloc_rename_retire.alloc_instr_o.vc_valid,
                dut.u_core.u_alloc_rename_retire.alloc_instr_o.instr.dest_address,

                dut.u_core.u_scalar_alu_rs.sc_rd_req0_o.valid,
                dut.u_core.u_scalar_alu_rs.sc_rd_req1_o.valid,
                dut.u_core.u_scalar_muldiv_rs.sc_rd_req_o.valid,
                dut.u_core.u_branch_rs.sc_rd_req_o.valid,
                dut.u_core.u_lsu_rs.ls_read_request_o.valid,
                dut.u_core.u_vector_alu_rs.vc_read_request_o.valid,

                dut.u_core.u_scalar_alu0.sc_ex_result_o.valid,
                dut.u_core.u_scalar_alu1.sc_ex_result_o.valid,
                dut.u_core.u_scalar_muldiv.sc_ex_result_o.valid,
                dut.u_core.u_branch.br_ex_result_o.valid,
                dut.u_core.u_lsu.lsu_output_o.valid,
                dut.u_core.u_vector_alu.vc_ex_result_o.valid,

                dut.u_core.u_scalar_writeback.data_bus_o.valid,
                dut.u_core.u_scalar_writeback.data_bus_o.prf_tag,
                dut.u_core.u_vector_writeback.data_bus_o.valid,
                dut.u_core.u_vector_writeback.data_bus_o.prf_tag,

                dut.u_core.u_reorder_buffer.retire_instr_o.valid,
                dut.u_core.u_reorder_buffer.retire_instr_o.prf_tag
        );
    endtask

    task automatic display_commit_states_sc();
        $display("[FINAL] R1:%h %h R2:%h %h R3:%h %h R4:%h %h R5:%h %h R6:%h %h R7:%h %h",
            dut.u_core.u_scalar_prf_replica0.regfile[dut.u_core.u_alloc_rename_retire.sc_commit_table[1]],
            dut.u_core.u_scalar_prf_replica1.regfile[dut.u_core.u_alloc_rename_retire.sc_commit_table[1]],
            dut.u_core.u_scalar_prf_replica0.regfile[dut.u_core.u_alloc_rename_retire.sc_commit_table[2]],
            dut.u_core.u_scalar_prf_replica1.regfile[dut.u_core.u_alloc_rename_retire.sc_commit_table[2]],
            dut.u_core.u_scalar_prf_replica0.regfile[dut.u_core.u_alloc_rename_retire.sc_commit_table[3]],
            dut.u_core.u_scalar_prf_replica1.regfile[dut.u_core.u_alloc_rename_retire.sc_commit_table[3]],
            dut.u_core.u_scalar_prf_replica0.regfile[dut.u_core.u_alloc_rename_retire.sc_commit_table[4]],
            dut.u_core.u_scalar_prf_replica1.regfile[dut.u_core.u_alloc_rename_retire.sc_commit_table[4]],
            dut.u_core.u_scalar_prf_replica0.regfile[dut.u_core.u_alloc_rename_retire.sc_commit_table[5]],
            dut.u_core.u_scalar_prf_replica1.regfile[dut.u_core.u_alloc_rename_retire.sc_commit_table[5]],
            dut.u_core.u_scalar_prf_replica0.regfile[dut.u_core.u_alloc_rename_retire.sc_commit_table[6]],
            dut.u_core.u_scalar_prf_replica1.regfile[dut.u_core.u_alloc_rename_retire.sc_commit_table[6]],
            dut.u_core.u_scalar_prf_replica0.regfile[dut.u_core.u_alloc_rename_retire.sc_commit_table[7]],
            dut.u_core.u_scalar_prf_replica1.regfile[dut.u_core.u_alloc_rename_retire.sc_commit_table[7]]
        );
    endtask

    task automatic display_commit_states_vc();
        $display("[FINAL] R1:%h R2:%h R3:%h R4:%h R5:%h R6:%h R7:%h",
            dut.u_core.u_vector_prf.regfile[dut.u_core.u_alloc_rename_retire.vc_commit_table[1]],
            dut.u_core.u_vector_prf.regfile[dut.u_core.u_alloc_rename_retire.vc_commit_table[2]],
            dut.u_core.u_vector_prf.regfile[dut.u_core.u_alloc_rename_retire.vc_commit_table[3]],
            dut.u_core.u_vector_prf.regfile[dut.u_core.u_alloc_rename_retire.vc_commit_table[4]],
            dut.u_core.u_vector_prf.regfile[dut.u_core.u_alloc_rename_retire.vc_commit_table[5]],
            dut.u_core.u_vector_prf.regfile[dut.u_core.u_alloc_rename_retire.vc_commit_table[6]],
            dut.u_core.u_vector_prf.regfile[dut.u_core.u_alloc_rename_retire.vc_commit_table[7]]
        );
    endtask