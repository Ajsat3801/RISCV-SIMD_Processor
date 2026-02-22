/*
    has 3 fields, Reg, value and ready

    For branch and Jump, target address calculated in decode and stored directly
    for branch, taken/not taken is stored in rd[0]
    

*/


module reorder_buffer #(
    parameter QUEUE_DEPTH = 8
)
(
    input logic clk,
    input logic reset_n,

    // connection with instruction queue

    
    //connection with common data bus
    common_data_bus_if.snoop CDB_data,

    // connection with reservation stations
    operation_bus_if.ROB rs_data,

    // connection with scalar registers
    output logic[4:0] writeback_rd,
    output logic[31:0] data,

    // connection with register allocation table (pre-dispatch)
    output logic[4:0] decoded_rd,
    output logic[4:0] ROB_id,

    // connection with register allocation table (writeback)



);

endmodule