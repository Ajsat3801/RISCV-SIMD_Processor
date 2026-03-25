
import circular_fifo_fwft_tb_config_pkg::*;

module top;

    logic clk;

    circular_fifo_fwft_if intf(clk);

    circular_fifo_fwft #(
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
        clk = 0;
        forever #2.5 clk = ~clk;
    end

    initial begin
        uvm_config_db #(virtual circular_fifo_fwft_if)::set(null,"*", "vif", intf);

        $dumpfile("dump.vcd");
        $dumpvars(0,top);

        run_test("circular_fifo_fwft_test_random50");
        //run_test("circular_fifo_fwft_test_fill_10_drain");
    end
  
endmodule