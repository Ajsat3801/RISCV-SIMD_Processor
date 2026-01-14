interface common_data_bus_if(input logic clk);

logic[4:0] cdb_ROB_ID;
logic cdb_data;
logic CDB_data_valid;

modport writeback(output cdb_ROB_ID, cdb_data, CDB_data_valid);
modport RS(input cdb_ROB_ID, cdb_data, CDB_data_valid);
modport ROB(input cdb_ROB_ID, cdb_data, CDB_data_valid);

endinterface