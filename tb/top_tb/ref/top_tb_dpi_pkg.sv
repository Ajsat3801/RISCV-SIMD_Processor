package top_tb_dpi_pkg;

localparam int VC_REG_NUM_ELEM = config_pkg::ARCH_REG_DEPTH*config_pkg::VECTOR_SIZE;

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
    int unsigned dmem_preload_data[config_pkg::VECTOR_SIZE],

    bit sc_prf_preload_en,
    int sc_prf_preload_addr,
    int unsigned sc_prf_preload_data,

    bit vc_prf_preload_en,
    int vc_prf_preload_addr,
    int unsigned vc_prf_preload_data[config_pkg::VECTOR_SIZE]
);

import "DPI-C" function void top_tb_ref_model_simulate(
    output int unsigned sc_regs_final[config_pkg::ARCH_REG_DEPTH],
    output int unsigned vc_regs_final[VC_REG_NUM_ELEM],
    output int unsigned dmem_final[config_pkg::DMEM_SIZE]
);
    

endpackage : top_tb_dpi_pkg