
package top_tb_config_pkg;

    parameter int unsigned IDLE_CYCLE_THRESHOLD = 512;

    parameter time TEST_TIMEOUT = 100ms;

    parameter signal_pkg::data_t TERMINATE = 32'h0000_0073;

    parameter logic [4:0] RESERVED_REG_LO = 5'd0;
    parameter logic [4:0] RESERVED_REG_HI = 5'd5;

//  -----------------------------------------------------------------------------------------------
//      Testbench config parameters derived from core_config_pkg
//  -----------------------------------------------------------------------------------------------

    localparam int unsigned DMEM_BANKS_N = core_config_pkg::VECTOR_LEN;

endpackage