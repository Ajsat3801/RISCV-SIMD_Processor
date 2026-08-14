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

    endfunction : sample

    /*  Keep track for number of cycles since the last retirement
     *  when the number crosses a treshold we terminate the testbench
     */
    
    int unsigned idle_cycles;
    int unsigned retire_count;
    logic started;
    logic compute_q;            // previous state of compute

    wire compute_now = dut.compute_i;
    wire retire_now  = dut.u_core.u_retirement_bus.valid;
    
    
    always @(posedge clk_i) begin
        if(!dut.reset_ni) begin

            idle_cycles <= 0;
            retire_count <= 0;
            started <= 1'b0;
            compute_q <= 1'b0;

        end

        else begin
            compute_q <= compute_now;

            if(retire_now) retire_count <= retire_count + 1;

            if(compute_now && !compute_q) begin
                started <= 1'b1;
                idle_cycles <= '0;
            end
            else if(retire_now) idle_cycles <= '0;
            else if(started) idle_cycles <= idle_cycles + 1;
            else idle_cycles <= '0;
        
        end
    end
    
    function automatic bit complete();

        return started && (idle_cycles >= top_tb_config_pkg::IDLE_CYCLE_THRESHOLD);

    endfunction : complete
    
endinterface : top_tb_if_retirement