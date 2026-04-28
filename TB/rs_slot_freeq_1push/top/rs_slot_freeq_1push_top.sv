import lib_rs_slot_freeq_1push_tb_config_pkg::*;

module top;

    logic clk;

    lib_rs_slot_freeq_1push_if intf(.clk(clk));

    lib_rs_slot_freeq_1push #(
        .BUFFER_SIZE(BUFFER_SIZE),
        .T(T)
    ) dut (
        .clk(clk),
        .reset_n(intf.reset_n),
        .push(intf.push),
        .push_data(intf.push_data),
        .pop(intf.pop),
        .data_out(intf.data_out),
        .empty(intf.empty),
        .full(intf.full)
    );

    initial begin
        clk = 1'b0;
        forever #2.5 clk = ~clk;
    end

    initial begin
        uvm_config_db #(virtual lib_rs_slot_freeq_1push_if)::set(null,"*","vif",intf);

        run_test("lib_rs_slot_freeq_1push_test_random50");
        // run_test("lib_rs_slot_freeq_1push_test_fill_10_drain");
        // run_test("lib_rs_slot_freeq_1push_test_drain_10_fill");

    end

endmodule