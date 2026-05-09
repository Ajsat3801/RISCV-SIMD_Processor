package lib_fifo_fwft_1push_tb_pkg;

    import uvm_pkg::*;
    `include "uvm_macros.svh"

    import lib_fifo_fwft_1push_tb_config_pkg::*;
    import lib_fifo_fwft_1push_dpi_pkg::*;

    `include "lib_fifo_fwft_1push_ref_model_adapter.sv"
    `include "lib_fifo_fwft_1push_tr.sv"
    `include "lib_fifo_fwft_1push_sqr.sv"
    `include "lib_fifo_fwft_1push_drv.sv"
    `include "lib_fifo_fwft_1push_mon.sv"
    `include "lib_fifo_fwft_1push_agt.sv"
    `include "lib_fifo_fwft_1push_base_seq.sv"
    `include "lib_fifo_fwft_1push_seq_fill_10_drain.sv"
    `include "lib_fifo_fwft_1push_seq_random50.sv"
    `include "lib_fifo_fwft_1push_scb.sv"
    `include "lib_fifo_fwft_1push_env.sv"
    `include "lib_fifo_fwft_1push_base_test.sv"
    `include "lib_fifo_fwft_1push_test_fill_10_drain.sv"
    `include "lib_fifo_fwft_1push_test_random50.sv"

endpackage