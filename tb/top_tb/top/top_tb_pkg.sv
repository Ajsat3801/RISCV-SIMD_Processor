package top_tb_pkg;

    import uvm_pkg::*;
    `include "uvm_macros.svh"

    import top_tb_dpi_pkg::*;
    import top_tb_typedef_pkg::*;

    // ---- run state -------------------------------------------------------------------------
    `include "top_tb_run_status.sv"

    // ---- transactions ----------------------------------------------------------------------
    `include "top_tb_tr_base.sv"
    `include "top_tb_tr_preload.sv"
    `include "top_tb_tr_compute.sv"
    `include "top_tb_tr_retire.sv"
    `include "top_tb_tr_dut_state.sv"

    // ---- reference model adapter (needs tr_preload) -----------------------------------------
    `include "top_tb_ref_model_adapter.sv"

    // ---- agent internals -------------------------------------------------------------------
    `include "top_tb_sqr.sv"
    `include "top_tb_drv.sv"
    `include "top_tb_mon_preload.sv"
    `include "top_tb_mon_retire.sv"
    `include "top_tb_mon_dut_state.sv"

    // ---- agents ----------------------------------------------------------------------------
    `include "top_tb_agt_preload.sv"
    `include "top_tb_agt_retire.sv"
    `include "top_tb_agt_dut_state.sv"

    // ---- analysis components (scb carries its own uvm_analysis_imp_decl calls) ---------------
    `include "top_tb_scb.sv"
    `include "top_tb_env.sv"

    // ---- sequences (program_base pulls in the instruction encoders) --------------------------
    `include "top_tb_instr_gen.sv"
    `include "top_tb_seq_base.sv"
    `include "top_tb_seq_preload.sv"
    `include "top_tb_seq_compute.sv"
    `include "top_tb_seq_program_base.sv"
    `include "top_tb_seq_sanity_check_directed_tb.sv"
    `include "top_tb_seq_random_tb.sv"

    // ---- tests -----------------------------------------------------------------------------
    `include "top_tb_test_base.sv"
    `include "top_tb_test_sanity_check_directed.sv"
    `include "top_tb_test_random.sv"

endpackage : top_tb_pkg