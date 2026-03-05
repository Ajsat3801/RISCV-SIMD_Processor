import config_pkg::*;

interface common_data_bus_if();

logic valid;
logic[ROB_ADDR_W-1:0] rob_id;
logic[DATA_SIZE-1:0] data;


modport writeback(output rob_id, data, valid);
modport snoop(input rob_id, data, valid);

endinterface