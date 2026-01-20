// temporary sv file to handle connections inside the ARR. 
// will be incorporated with core.sv later on

module ooo_dispatch_top (
    input logic clk,
    input logic reset_n,
    // ... other system signals (CDB, etc)
);

    // 1. Instantiate the Interface with 5 RS entries
    operation_bus_if #(.NUM_RS(2)) op_bus();

    // 2. Instantiate 5 Reservation Stations
    // Each is assigned a unique CHIP_SELECT ID
    reservation_station #(.CHIP_SELECT(1)) rs_alu (
        .clk(clk), .reset_n(reset_n),
        .rs_data(op_bus.RS), // Connects to the RS modport
        .rs_full(op_bus.rs_full_vec[1]), // Manual stitch to vector
        .CDB_data(CDB_bus_if.snoop),
        // ... execution unit ports
    );

    reservation_station #(.CHIP_SELECT(2)) rs_muldiv (
        .clk(clk), .reset_n(reset_n),
        .rs_data(op_bus.RS),
        .rs_full(op_bus.rs_full_vec[2]),
        .CDB_data(CDB_bus_if.snoop),
        // ...
    );


    // 3. Instantiate your Sources
    // They interact with the op_bus via their respective modports
    rat_module my_rat (.bus(op_bus.RAT), ...);
    rob_module my_rob (.bus(op_bus.ROB), ...);
    reg_module my_reg (.bus(op_bus.Registers), ...);

endmodule