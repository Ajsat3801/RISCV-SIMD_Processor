interface top_tb_if_retirement (input logic clk_i);

    function automatic top_tb_typedef_pkg::retire_snapshot_t sample();
        /*  Samples the retirement bus and returns a struct with the sampled values
         *  (pretty much an interface for the rest of the testbench to see the dut values)
         */
        
        sample.valid = dut.u_core.u_retirement_bus.valid;

        sample.prf_tag = dut.u_core.u_retirement_bus.prf_tag;
        sample.rob_id = dut.u_core.u_retirement_bus.rob_id;

        sample.data = dut.u_core.u_retirement_bus.data;

        sample.write_to_reg = dut.u_core.u_retirement_bus.write_to_reg;
        sample.dest_address = dut.u_core.u_retirement_bus.dest_address;

        sample.is_branch = dut.u_core.u_retirement_bus.is_branch;
        sample.branch_taken = dut.u_core.u_retirement_bus.branch_taken;

    endfunction

    /*  Keep track for number of cycles since the last retirement
     *  when the number crosses a treshold we terminate the testbench
     */
    
    int unsigned idle_cycles;

    always @(posedge clk_i) begin

        if (dut.u_core.u_retirement_bus.valid) idle_cycles <= '0;
        else idle_cycles <= idle_cycles + 1'b1;

    end

endinterface