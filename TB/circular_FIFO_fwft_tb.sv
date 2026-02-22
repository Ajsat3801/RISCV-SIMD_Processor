`timescale 1ns/1ps
module circular_FIFO_fwft_tb;

localparam DATA_SIZE = 3;

logic clk, reset_n, enqueue, dequeue, empty, full;
logic[DATA_SIZE-1:0] enqueue_data, dequeue_data;
    

circular_FIFO_fwft #(.DATA_SIZE(DATA_SIZE)) dut (
    .clk(clk),
    .reset_n(reset_n),
    .enqueue(enqueue),
    .enqueue_data(enqueue_data),
    .dequeue(dequeue),
    .dequeue_data(dequeue_data),
    .empty(empty),
    .full(full)
);

initial clk = 1'b0;
always #5 clk = !clk;

task idle();
begin
    reset_n = 0;
    enqueue = 0;
    dequeue = 0;
    enqueue_data = 0;
  	#10;
    reset_n = 1;
end
endtask



task automatic test_FWFT_no_enqueue();
begin
    dequeue = 1;
    #20;
    dequeue = 0;
    #40
    dequeue = 1;
    $monitor("time=%t\tdequeue_Data = %d" ,$time,dequeue_data );
end
endtask

initial begin
    idle();
    $display("test begin ---------------------");
    test_FWFT_no_enqueue();
    #150;
    $finish;
end
  
  initial begin
    $dumpfile("dump.vcd");
	$dumpvars(0, circular_FIFO_fwft_tb);
  end

endmodule