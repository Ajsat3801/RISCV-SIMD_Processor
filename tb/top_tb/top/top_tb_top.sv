import uvm_pkg::*;

module top_tb_top;

    logic clk;
    logic reset_n;

    initial begin
        reset_n = 1'b0;
        repeat(5) @(posedge clk);
        reset_n = 1'b1;

    end

    initial begin
        clk = 1'b0;
        forever #10 clk = ~clk;      // 20ns period
    end

    top_tb_if_preload u_preload_if(.clk_i(clk), .reset_ni(reset_n));
    top_tb_if_retirement u_retire_if(.clk_i(clk));
    top_tb_if_dut_state u_dut_state_if(.clk_i(clk));
    top_tb_if_alloc u_alloc_if(.clk_i(clk));
    top_tb_if_axi u_axi_if(.clk_i(clk), .reset_ni(reset_n));

    top dut (
        .clk_i(clk),
        .reset_ni(reset_n),
        .compute_i(u_preload_if.compute),

        .imem_preload_en_i(u_preload_if.imem_preload_en),
        .preload_imem_request_i(u_preload_if.preload_imem_request),

        .axi_connection(u_axi_if.master)
    );

    initial begin
        uvm_config_db #(virtual top_tb_u_preload_if)::set(null, "*","vif_preload", if_preload);
        uvm_config_db #(virtual top_tb_if_retirement)::set(null, "*", "vif_retire", u_retire_if);
        uvm_config_db #(virtual top_tb_if_dut_state)::set(null, "*","vif_dut_state", u_dut_state_if);
        uvm_config_db #(virtual top_tb_if_alloc)::set(null, "*","vif_alloc", u_alloc_if);
        uvm_config_db #(virtual if_axi)::set(null, "*", "vif_axi", u_axi_if);

        //run_test("top_tb_test_sanity_check_directed");
        run_test("top_tb_test_random");
    end

endmodule : top_tb_top

