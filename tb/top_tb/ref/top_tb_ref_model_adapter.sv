import top_tb_dpi_pkg::*;

class top_tb_ref_model_adapter;

    localparam int VC_REG_NUM_ELEM = config_pkg::ARCH_REG_DEPTH*config_pkg::VECTOR_SIZE;
    localparam int VLEN = config_pkg::VECTOR_SIZE;
    function void create_model();

        top_tb_ref_model_init (
            config_pkg::IMEM_NUM_WORDS,
            config_pkg::DMEM_NUM_WORDS,
            config_pkg::VECTOR_SIZE
        );

    endfunction : create_model

    function void preload(
        input top_tb_tr_preload tr
    );

        bit imem_preload_en_i = bit'(tr.imem_en);
        int imem_preload_addr_i = tr.imem_address;
        int unsigned imem_preload_data_i = tr.imem_data;

        bit dmem_preload_en_i = bit'(tr.dmem_en);
        int dmem_preload_write_enable_i = tr.dmem_write_enable; // ignored because used only during operation
        int dmem_preload_addr_i = tr.dmem_address;

        int unsigned dmem_preload_data_i[config_pkg::VECTOR_SIZE]; 
        for(int i=0; i<config_pkg::VECTOR_SIZE; i++)
            dmem_preload_data_i[i] = tr.dmem_data[i];

        bit sc_prf_preload_en_i = bit'(tr.sc_prf_en);
        int sc_prf_preload_addr_i = tr.sc_prf_address;
        int unsigned sc_prf_preload_data_i = tr.sc_prf_data;

        bit vc_prf_preload_en_i = bit'(tr.vc_prf_en);
        int vc_prf_preload_addr_i = tr.vc_prf_address;

        int unsigned vc_prf_preload_data_i[config_pkg::VECTOR_SIZE];
        for(int i=0; i<config_pkg::VECTOR_SIZE; i++)
            vc_prf_preload_data_i[i] = tr.vc_prf_data[i];
        
        top_tb_ref_model_preload (
            .imem_preload_en(imem_preload_en_i),
            .imem_preload_addr(imem_preload_addr_i),
            .imem_preload_data(imem_preload_data_i),

            .dmem_preload_en(dmem_preload_en_i),
            .dmem_preload_write_enable(dmem_preload_write_enable_i), // ignored because used only during operation
            .dmem_preload_addr(dmem_preload_addr_i),
            .dmem_preload_data(dmem_preload_data_i),

            .sc_prf_preload_en(sc_prf_preload_en_i),
            .sc_prf_preload_addr(sc_prf_preload_addr_i),
            .sc_prf_preload_data(sc_prf_preload_data_i),

            .vc_prf_preload_en(vc_prf_preload_en_i),
            .vc_prf_preload_addr(vc_prf_preload_addr_i),
            .vc_prf_preload_data(vc_prf_preload_data_i)
        );

    endfunction : preload

    function void simulate(
        output signal_pkg::data_t sc_reg_res[config_pkg::ARCH_REG_DEPTH],
        output signal_pkg::vector_data_t vc_reg_res[config_pkg::ARCH_REG_DEPTH],
        output signal_pkg::data_t dmem_res[config_pkg::DMEM_SIZE]
    );

        int unsigned sc_reg_res_o[config_pkg::ARCH_REG_DEPTH];
        int unsigned vc_reg_res_o[VC_REG_NUM_ELEM];
        int unsigned dmem_res_o[config_pkg::DMEM_SIZE];
        
        top_tb_ref_model_simulate(
            .sc_regs_final(sc_reg_res_o),
            .vc_regs_final(vc_reg_res_o),
            .dmem_final(dmem_res_o)
        );

        for(int i=0; i<config_pkg::ARCH_REG_DEPTH; i++) sc_reg_res[i] = sc_reg_res_o[i];

        for(int i=0; i<config_pkg::ARCH_REG_DEPTH; i++) begin
            vc_reg_res[i] = '{  vc_reg_res_o[(VLEN*i)+3],
                                vc_reg_res_o[(VLEN*i)+2],
                                vc_reg_res_o[(VLEN*i)+1],
                                vc_reg_res_o[(VLEN*i)]};
        end

        for(int i=0; i<config_pkg::DMEM_SIZE; i++) dmem_res[i] = dmem_res_o[i];

    endfunction : simulate

endclass : top_tb_ref_model_adapter