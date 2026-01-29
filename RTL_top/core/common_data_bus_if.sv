interface common_data_bus_if(input logic clk);

logic[4:0] ROB_id;
logic[31:0] data;
logic valid;

modport writeback(output ROB_id, data, valid);
modport snoop(input ROB_id, data, valid);

endinterface