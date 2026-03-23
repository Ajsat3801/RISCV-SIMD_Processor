package circular_fifo_fwft_tb_pkg;

    import uvm_pkg::*;
    `include "uvm_macros.svh"

    import circular_fifo_fwft_tb_config_pkg::*;
    import circular_fifo_fwft_dpi_pkg::*;

    `include "circular_fifo_fwft_ref_model_adapter.sv"
    `include "circular_fifo_fwft_tr.sv"
    `include "circular_fifo_fwft_sqr.sv"
    `include "circular_fifo_fwft_drv.sv"
    `include "circular_fifo_fwft_mon.sv"
    `include "circular_fifo_fwft_agt.sv"
    `include "circular_fifo_fwft_base_seq.sv"
    `include "circular_fifo_fwft_seq_fill_10_drain.sv"
    `include "circular_fifo_fwft_seq_random50.sv"
    `include "circular_fifo_fwft_scb.sv"
    `include "circular_fifo_fwft_env.sv"
    `include "circular_fifo_fwft_base_test.sv"
    `include "circular_fifo_fwft_test_fill_10_drain.sv"
    `include "circular_fifo_fwft_test_random50.sv"

endpackage