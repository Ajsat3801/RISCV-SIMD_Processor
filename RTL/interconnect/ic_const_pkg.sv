package ic_const_pkg;
    /*
     *  constants used in AXI config signals. 
     */
    import ic_config_pkg::*;

    parameter  logic       AXLOCK = 1'b0;
    parameter  logic [3:0] AXCACHE = 4'b1111;
    parameter  logic [2:0] AXPROT_D = 3'b001;
    parameter  logic [2:0] AXPROT_I = 3'b101;
    parameter  logic [3:0] AXQOS = 4'b0000;
    parameter  logic [DATA_WIDTH/8-1:0] WSTRB = '1;

    localparam logic [7:0] AXLEN = 8'(LINE_W / DATA_WIDTH - 1);
    localparam logic [2:0] AXSIZE = 3'($clog2(DATA_WIDTH/8));

endpackage