package ic_config_pkg;

    parameter int unsigned ADDR_WIDTH = 32;     // must be greater than physical mem address width
    parameter int unsigned DATA_WIDTH = 128;    // line width must be a multiple of data width
    parameter int unsigned ID_W_WIDTH = 1;      // number of outstanding writes per master
    parameter int unsigned ID_R_WIDTH = 1;      // number of outstanding reads per master

//  -----------------------------------------------------------------------------------------------
//          Derived parameters
//  -----------------------------------------------------------------------------------------------
    localparam int unsigned LINE_W = core_config_pkg::DATA_W * core_config_pkg::VECTOR_LEN;
    localparam logic [7:0] AXLEN = 8'(LINE_W / DATA_WIDTH - 1);
    localparam logic [2:0] AXSIZE = 3'(clog2(DATA_WIDTH/8));

endpackage