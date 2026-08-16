
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

    top_tb_if_preload if_preload(.clk_i(clk), .reset_ni(reset_n));
    top_tb_if_retirement if_retire(.clk_i(clk));
    top_tb_if_dut_state if_dut_state(.clk_i(clk));

    top dut (
        .clk_i(clk),
        .reset_ni(reset_n),

        .compute_i(if_preload.compute),

        .imem_preload_en_i(if_preload.imem_preload_en),
        .preload_imem_request_i(if_preload.preload_imem_request),

        .dmem_preload_en_i(if_preload.dmem_preload_en),
        .preload_dmem_request_i(if_preload.preload_dmem_request),

        .sc_prf_preload_en_i(if_preload.sc_prf_preload_en),
        .sc_prf_preload_data_i(if_preload.sc_prf_preload_data),
        .sc_prf_preload_addr_i(if_preload.sc_prf_preload_addr),

        .vc_prf_preload_en_i(if_preload.vc_prf_preload_en),
        .vc_prf_preload_data_i(if_preload.vc_prf_preload_data),
        .vc_prf_preload_addr_i(if_preload.vc_prf_preload_addr)
    );

    initial begin
        uvm_config_db #(virtual top_tb_if_preload)::set(null, "*","vif_preload", if_preload);
        uvm_config_db #(virtual top_tb_if_retirement)::set(null, "*", "vif_retire", if_retire);
        uvm_config_db #(virtual top_tb_if_dut_state)::set(null, "*","vif_dut_state", if_dut_state);

        run_test("top_tb_test_sanity_check_directed");
    end

endmodule : top_tb_top

