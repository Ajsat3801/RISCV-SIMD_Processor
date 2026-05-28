    
    task automatic display_prf_sc();
        $display("[SC PRF] R1:%h %h R2:%h %h R3:%h %h R4:%h %h R5:%h %h R6:%h %h R7:%h %h",
            dut.u_core.u_scalar_prf_replica0.regfile[1],
            dut.u_core.u_scalar_prf_replica1.regfile[1],
            dut.u_core.u_scalar_prf_replica0.regfile[2],
            dut.u_core.u_scalar_prf_replica1.regfile[2],
            dut.u_core.u_scalar_prf_replica0.regfile[32],
            dut.u_core.u_scalar_prf_replica1.regfile[32],
            dut.u_core.u_scalar_prf_replica0.regfile[33],
            dut.u_core.u_scalar_prf_replica1.regfile[33],
            dut.u_core.u_scalar_prf_replica0.regfile[34],
            dut.u_core.u_scalar_prf_replica1.regfile[34],
            dut.u_core.u_scalar_prf_replica0.regfile[35],
            dut.u_core.u_scalar_prf_replica1.regfile[35],
            dut.u_core.u_scalar_prf_replica0.regfile[36],
            dut.u_core.u_scalar_prf_replica1.regfile[36]
        );
    endtask

    task automatic display_prf_vc();
        $display("[VC PRF] R1:%h R2:%h R3:%h",
            dut.u_core.u_vector_prf.regfile[1],
            dut.u_core.u_vector_prf.regfile[2],
            dut.u_core.u_vector_prf.regfile[32],
        );
    endtask

    task automatic display_prf_inout_sc();
        $display("[PRF IN] IN:[%b @ %d (%h)] PRECALC:[%b @ %d (%h)]",
            dut.u_core.u_scalar_prf_replica0.sc_wb_instr_i.valid,
            dut.u_core.u_scalar_prf_replica0.sc_wb_instr_i.prf_tag,
            dut.u_core.u_scalar_prf_replica0.sc_wb_instr_i.data,
            dut.u_core.u_scalar_prf_replica0.precalc_i.precalc_valid,
            dut.u_core.u_scalar_prf_replica0.precalc_i.precalc_prf_tag,
            dut.u_core.u_scalar_prf_replica0.precalc_i.precalc_data
        );
    endtask

    task automatic display_prf_inout_ls();
    $display("[PRF IN] sc: [%b @ %d (%0d %0d)]",
            dut.u_core.u_scalar_prf_replica1.ls_rd_req_i.valid,
            dut.u_core.u_scalar_prf_replica1.ls_rd_req_i.prf_tag,
            dut.u_core.u_scalar_prf_replica1.ls_rd_req_i.operand_a_tag,
            dut.u_core.u_scalar_prf_replica1.ls_rd_req_i.operand_b_tag,
        );
    endtask

    task automatic display_prf_inout_br();
    $display("[BR PRF IN] in: [%b @ %d (%0d %0d)] out: [%b @ %d (%0d %0d)]",
            dut.u_core.u_scalar_prf_replica1.sc_br_rd_req_i.valid,
            dut.u_core.u_scalar_prf_replica1.sc_br_rd_req_i.prf_tag,
            dut.u_core.u_scalar_prf_replica1.sc_br_rd_req_i.operand_a_tag,
            dut.u_core.u_scalar_prf_replica1.sc_br_rd_req_i.operand_b_tag,

            dut.u_core.u_scalar_prf_replica1.sc_br_ex_req_o.valid,
            dut.u_core.u_scalar_prf_replica1.sc_br_ex_req_o.prf_tag,
            dut.u_core.u_scalar_prf_replica1.sc_br_ex_req_o.operand_a,
            dut.u_core.u_scalar_prf_replica1.sc_br_ex_req_o.operand_b,
        );
    endtask

    task automatic display_prf_inout_vc();
        $display("[PRF INOUT] IN:[%b @ %0d (%b %b)] OUT:[%b - %h %h]",
            dut.u_core.u_vector_prf.vc_alu_rd_req_i.valid,
            dut.u_core.u_vector_prf.vc_alu_rd_req_i.prf_tag,
            dut.u_core.u_vector_prf.vc_alu_rd_req_i.operand_a_tag,
            dut.u_core.u_vector_prf.vc_alu_rd_req_i.operand_b_tag,
            dut.u_core.u_vector_prf.vc_alu_ex_req_o.valid,
            dut.u_core.u_vector_prf.vc_alu_ex_req_o.operand_a,
            dut.u_core.u_vector_prf.vc_alu_ex_req_o.operand_b
        );
    endtask