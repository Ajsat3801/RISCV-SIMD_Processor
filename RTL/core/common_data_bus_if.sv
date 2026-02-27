interface common_data_bus_if();

logic valid;
logic[ROB_ADDR_W-1:0] rob_id;
logic[31:0] data;
logic branch; // Branch is 0 only then snoop done


modport writeback(output rob_id, data, branch, valid);
modport snoop(input rob_id, data, branch, valid);

endinterface


/*
    When Branch is 0, ROBID and Data work as usual
    When Branch is 1, 
        ROBID[0] will determine taken/not taken
        Data will determine new PC

*/