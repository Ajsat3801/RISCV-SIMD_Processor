interface common_data_bus_if(input logic clk);

logic[4:0] ROB_id;
logic data;
logic valid;

modport writeback(output ROB_id, data, valid);
modport RS(input ROB_id, data, valid);
modport ROB(input ROB_id, data, valid);

endinterface