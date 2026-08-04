interface top_tb_if_dut_state (input logic clk_i);

    //  -------------------------------------------------------------------------------------------
    //                         BFM for reading scalar register values
    //  -------------------------------------------------------------------------------------------

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

    endfunction : sc_replicas_match
    

    function automatic signal_pkg::data_t get_sc_prf_data (
        signal_pkg::prf_tag_t address
    );
        // Returns the data present in the input address of the PRF
        get_sc_prf_data = dut.u_core.u_scalar_prf_replica0.regfile[address.tag];

    endfunction : get_sc_prf_data


    function automatic signal_pkg::data_t get_sc_reg (
        signal_pkg::arf_address_t address
    );
        // Returns the data present in the PRF address mapped to the input in the RAT

        get_sc_reg = dut.u_core.u_scalar_prf_replica0.regfile [
            dut.u_core.u_alloc_rename_retire.sc_commit_table [address]];

    endfunction : get_sc_reg


    function automatic void dump_sc_regs (
        output signal_pkg::data_t arr[config_pkg::ARCH_REG_DEPTH],
        output logic match
    );
        // Dumps the arch register values from R0 to R31
        for(int i=0; i<config_pkg::ARCH_REG_DEPTH; i++) begin
            arr[i] = get_sc_reg(i);
        end

        match = sc_replicas_match();

    endfunction : dump_sc_regs

    //  -------------------------------------------------------------------------------------------
    //                         BFM for reading vector register values
    //  -------------------------------------------------------------------------------------------

    function automatic signal_pkg::vector_data_t get_vc_prf_data (
        signal_pkg::prf_tag_t address
    ); 
        // Returns the data present in the input address of the PRF
        get_vc_prf_data = dut.u_core.u_vector_prf.regfile[address.tag];

    endfunction : get_vc_prf_data


    function automatic signal_pkg::vector_data_t get_vc_reg (
        signal_pkg::arf_address_t address
    );
        // Returns the data present in the PRF address mapped to the input in the RAT
        get_vc_reg = dut.u_core.u_vector_prf.regfile [
            dut.u_core.u_alloc_rename_retire.vc_commit_table [address]];

    endfunction : get_vc_reg


    function automatic void dump_vc_regs (
        output signal_pkg::vector_data_t arr[config_pkg::ARCH_REG_DEPTH]
    );
        // Dumps the arch register values from V0 to V31
        for(int i=0; i<config_pkg::ARCH_REG_DEPTH; i++) begin
            arr[i] = get_vc_reg(i);
        end
        
    endfunction : dump_vc_regs

    //  -------------------------------------------------------------------------------------------
    //                              BFM for reading DMEM values
    //  -------------------------------------------------------------------------------------------

    function automatic signal_pkg::vector_data_t get_dmem_row(
        signal_pkg::dmem_address_t address
    );
        // returns one row of DMEM data across banks
        // row[i] = value in row at bank i
        get_dmem_row[0] = dut.u_dmem.u_dmem0.mem[address[config_pkg::DMEM_ADDR_SIZE-1:2]][31:0];
        get_dmem_row[1] = dut.u_dmem.u_dmem1.mem[address[config_pkg::DMEM_ADDR_SIZE-1:2]][31:0];
        get_dmem_row[2] = dut.u_dmem.u_dmem2.mem[address[config_pkg::DMEM_ADDR_SIZE-1:2]][31:0];
        get_dmem_row[3] = dut.u_dmem.u_dmem3.mem[address[config_pkg::DMEM_ADDR_SIZE-1:2]][31:0];

    endfunction : get_dmem_row


    function automatic void dump_dmem(
        output signal_pkg::data_t arr[config_pkg::DMEM_SIZE]
    );
        // dumps full DMEM values
        // note: output data is not banked
        for(int i=0; i<config_pkg::DMEM_SIZE; i+=4) begin
            signal_pkg::vector_data_t row = get_dmem_row(i);
            arr[i] = row[0];
            arr[i+1] = row[1];
            arr[i+2] = row[2];
            arr[i+3] = row[3];
        end
    endfunction : dump_dmem

endinterface : top_tb_if_dut_state