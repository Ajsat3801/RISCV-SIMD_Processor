interface common_data_bus_if();

logic[4:0] ROB_id;
logic[31:0] data;
logic branch; // Branch is 0 only then snoop done
logic valid;

logic instr_valid = ~branch && valid;

modport writeback(output ROB_id, data, branch, valid);
modport RSsnoop(input ROB_id, data, instr_valid);
modport ROBsnoop(input ROB_id, data, branch, valid);

endinterface


/*
    When Branch is 0, ROBID and Data work as usual
    When Branch is 1, 
        ROBID[0] will determine taken/not taken
        Data will determine new PC

*/