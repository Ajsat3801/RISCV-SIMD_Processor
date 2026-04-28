package lib_rs_slot_freeq_1push_tb_pkg;

    import uvm_pkg::*;
    `include "uvm_macros.svh"

    import lib_rs_slot_freeq_1push_tb_config_pkg::*;
    import lib_rs_slot_freeq_1push_dpi_pkg::*;

    `include "lib_rs_slot_freeq_1push_ref_model_adapter.sv"

    // test agent
    `include "lib_rs_slot_freeq_1push_tr.sv"
    `include "lib_rs_slot_freeq_1push_sqr.sv"
    `include "lib_rs_slot_freeq_1push_drv.sv"
    `include "lib_rs_slot_freeq_1push_mon.sv"
    `include "lib_rs_slot_freeq_1push_agt.sv"
    
    // test sequences
    `include "lib_rs_slot_freeq_1push_base_seq.sv"
    `include "lib_rs_slot_freeq_1push_seq_random50.sv"
    `include "lib_rs_slot_freeq_1push_seq_fill_10_drain.sv"
    `include "lib_rs_slot_freeq_1push_seq_drain_10_fill.sv"

    // test environments
    `include "lib_rs_slot_freeq_1push_scb.sv"
    `include "lib_rs_slot_freeq_1push_env.sv"

    // tests
    `include "lib_rs_slot_freeq_1push_base_test.sv"
    `include "lib_rs_slot_freeq_1push_test_random50.sv"
    `include "lib_rs_slot_freeq_1push_test_fill_10_drain.sv"
    `include "lib_rs_slot_freeq_1push_test_drain_10_fill.sv"

endpackage