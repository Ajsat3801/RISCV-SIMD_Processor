interface top_tb_if_prf_sample (input logic clk_i);

    function automatic bit sc_replicas_match();

        /*  Task to check whether the 2 replicas of the scalar PRF match 
         *  Checks all 64 registers, irrespective of whether its assigned to an ARF or not
         *  Returns boolean value, 1 is true, 0 is false
         */

        bit match = 1'b1;

        for(int i=0; i<config_pkg::PRF_DEPTH; i++) begin
            match &= (dut.u_core.u_scalar_prf_replica0.regfile[i] ==
                      dut.u_core.u_scalar_prf_replica1.regfile[i]);
        end
        sc_replicas_match = match;

    endfunction

    function automatic signal_pkg::data_t get_sc_prf_data(signal_pkg::prf_tag_t address);
        
        get_sc_prf_data = dut.u_core.u_scalar_prf_replica0.regfile[address.tag];

    endfunction

    function automatic signal_pkg::data_t get_sc_reg (signal_pkg::arf_address_t address);

        get_sc_reg = dut.u_core.u_scalar_prf_replica0.regfile [
            dut.u_core.u_alloc_rename_retire.sc_commit_table [address]];

    endfunction

    function automatic void dump_sc_regs (
        output signal_pkg::data_t arr[config_pkg::ARCH_REG_DEPTH],
        output logic match
    );
        for(int i=0; i<config_pkg::ARCH_REG_DEPTH; i++) begin
            arr[i] = get_sc_reg(i);
        end

        match = sc_replicas_match();

    endfunction


    function automatic signal_pkg::vector_data_t get_vc_prf_data(signal_pkg::prf_tag_t address);
        
        get_vc_prf_data = dut.u_core.u_vector_prf.regfile[address.tag];

    endfunction

    function automatic signal_pkg::vector_data_t get_vc_reg (signal_pkg::arf_address_t address);

        get_vc_reg = dut.u_core.u_vector_prf.regfile [
            dut.u_core.u_alloc_rename_retire.vc_commit_table [address]];

    endfunction

    function automatic void dump_vc_regs (
        output signal_pkg::vector_data_t arr[config_pkg::ARCH_REG_DEPTH]
    );
        for(int i=0; i<config_pkg::ARCH_REG_DEPTH; i++) begin
            arr[i] = get_vc_reg(i);
        end
        
    endfunction

endinterface