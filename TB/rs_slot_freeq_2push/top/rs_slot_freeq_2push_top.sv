
module top;

    bit clk;
    lib_rs_slot_freeq_2push_if intf(.clk_i(clk));

    lib_rs_slot_freeq_2push #(
        .BUFFER_SIZE(BUFFER_SIZE),
        .T(T)
    ) dut (
        .clk_i(clk),
        .reset_ni(intf.reset_n),
        .push1_i(intf.push1),
        .push_data1_i(intf.push_data1),
        .push2_i(intf.push2),
        .push_data2_i(intf.push_data2),
        .pop_o(intf.pop),
        .data_out_o(intf.data_out),
        .empty_o(intf.empty),
        .full_o(intf.full)
    );

    initial begin
        clk = 1'b0;
        forever #2.5 clk = ~clk;
    end

    initial begin
        uvm_config_db #(virtual lib_rs_slot_freeq_2push_if)::set(null,"*","vif",intf);
        run_test("lib_rs_slot_freeq_2push_test_random50");
    end

endmodule