package ic_config_pkg;
    /*
     *  Configurable parameters for AXI interconnect
     */

    parameter int unsigned ADDR_WIDTH = 32;     // must be greater than or same as physical mem address width
    parameter int unsigned DATA_WIDTH = 128;    // line width must be a multiple of data width
    parameter int unsigned ID_W_WIDTH = 1;      // number of outstanding writes per master
    parameter int unsigned ID_R_WIDTH = 1;      // number of outstanding reads per master

    // Line width is the total size of the data to be sent using an interconnect
    localparam int unsigned LINE_W = core_config_pkg::DATA_W * core_config_pkg::VECTOR_LEN;

endpackage