`include "circular_fifo_fwft_if.sv"
`include "circular_fifo_fwft_transaction.sv"
`include "circular_fifo_fwft_sequence.sv"
`include "circular_fifo_fwft_sequence_random50.sv"
`include "circular_fifo_fwft_sequence_fill_10_drain.sv"
`include "circular_fifo_fwft_driver.sv"
`include "circular_fifo_fwft_monitor.sv"
`include "circular_fifo_fwft_sequencer.sv"
`include "circular_fifo_fwft_agent.sv"
`include "circular_fifo_fwft_scoreboard.sv"
`include "circular_fifo_fwft_unit_env.sv"
`include "circular_fifo_fwft_test.sv"
`include "circular_fifo_fwft_test_random50.sv"
`include "circular_fifo_fwft_test_fill_10_drain.sv"

module top;

    parameter int BUFFER_SIZE = 8;
    parameter type T = logic[31:0];

    logic clk;
    logic reset_n;

    circular_fifo_fwft_if #(BUFFER_SIZE, T) intf(clk);

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
        forever #10 clk = ~clk;
    end

    initial begin
        uvm_config_db #(virtual circular_fifo_fwft_if #(BUFFER_SIZE, T))::set(null,"*", "vif", intf);

        $dumpfile("dump.vcd");
        $dumpvars(0,top);

        //run_test("circular_fifo_fwft_test_random50");
        run_test("circular_fifo_fwft_test_fill_10_drain");
    end
  
endmodule