package top_tb_dpi_pkg;

localparam int VC_REG_NUM_ELEM = core_config_pkg::ARCH_REG_DEPTH*core_config_pkg::VECTOR_LEN;

import "DPI-C" function void top_tb_ref_model_init(
    int imem_num_words,
    int dmem_num_words,
    int vlen
);

import "DPI-C" function void top_tb_ref_model_preload(
    bit imem_preload_en,
    int imem_preload_addr,
    int unsigned imem_preload_data,

    bit dmem_preload_en,
    int dmem_preload_write_enable, // ignored because used only during operation
    int dmem_preload_addr,
    int unsigned dmem_preload_data[core_config_pkg::VECTOR_LEN],

    bit sc_prf_preload_en,
    int sc_prf_preload_addr,
    int unsigned sc_prf_preload_data,

    bit vc_prf_preload_en,
    int vc_prf_preload_addr,
    int unsigned vc_prf_preload_data[core_config_pkg::VECTOR_LEN]
);

import "DPI-C" function void top_tb_ref_model_simulate(
    output int unsigned sc_regs_final[core_config_pkg::ARCH_REG_DEPTH],
    output int unsigned vc_regs_final[VC_REG_NUM_ELEM],
    output int unsigned dmem_final[core_config_pkg::DMEM_DEPTH]
);
    

endpackage : top_tb_dpi_pkg