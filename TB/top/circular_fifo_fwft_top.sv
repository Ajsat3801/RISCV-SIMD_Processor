
module top;

    parameter int BUFFER_SIZE = 8;
    parameter type T = logic[31:0];

    logic clk;
    logic reset_n;

    circular_fifo_fwft_if #(BUFFER_SIZE, T) intf(clk, reset_n);

    circular_fifo_fwft #(
        .BUFFER_SIZE(BUFFER_SIZE),
        .T(T)
    ) dut (
        .clk(clk),
        .reset_n(reset_n),
        .push(intf.push),
        .push_data(intf.push_data),
        .pop(intf.pop),
        .data_out(intf.data_out),
        .empty(intf.empty),
        .full(intf.full)
    );

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    initial begin
        reset_n = 0;
        #20;
        reset_n = 1;
    end

    initial begin
        uvm_config_db #(virtual circular_fifo_fwft_if #(BUFFER_SIZE, T))::set(null,"*", vif, intf);

        $dumpfile("dump.vcd");
        $dumpvars(0,top);

        run_test("circular_fifo_fwft_test");
    end
endmodule