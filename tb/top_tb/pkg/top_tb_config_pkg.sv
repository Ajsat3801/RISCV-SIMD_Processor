
package top_tb_config_pkg;

    parameter int unsigned IDLE_CYCLE_THRESHOLD = 64;

    parameter time TEST_TIMEOUT = 100ms;

    parameter signal_pkg::data_t TERMINATE = 32'h0000_0073;

endpackage