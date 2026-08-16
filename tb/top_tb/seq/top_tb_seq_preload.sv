
class top_tb_seq_preload extends top_tb_seq_base;

    `uvm_object_utils(top_tb_seq_preload)

    signal_pkg::data_t imem_preload[];
    signal_pkg::vector_data_t dmem_preload[];
    signal_pkg::data_t sc_prf_preload[];
    signal_pkg::vector_data_t vc_prf_preload[];

    function new(string name="top_tb_seq_preload");
        super.new(name);
    endfunction

    virtual task body();

        int unsigned n_cycles;
        bit sc_reg_active, vc_reg_active;
        
        signal_pkg::data_t imem_data;
        signal_pkg::data_t sc_prf_data;
        signal_pkg::vector_data_t vc_prf_data;
        signal_pkg::vector_data_t dmem_data;

        if(imem_preload.size() == 0) `uvm_fatal("SEQ/NO_PRELOAD","Imem preload array empty")
        if(dmem_preload.size() == 0) `uvm_fatal("SEQ/NO_PRELOAD","DMEM preload array empty")
        if(sc_prf_preload.size() == 0) `uvm_fatal("SEQ/NO_PRELOAD","Scalar Register preload array empty")
        if(vc_prf_preload.size() == 0) `uvm_fatal("SEQ/NO_PRELOAD","Vector Register preload array empty")

        if(imem_preload.size() > config_pkg::IMEM_NUM_WORDS) `uvm_fatal("SEQ/IMEM_OVERLOW", "Imem overflow")
        if(imem_preload[imem_preload.size()-1]!= top_tb_config_pkg::TERMINATE) `uvm_fatal("SEQ/NO_TERMINATE","Missing terminate in instruction sequence")
        
        if(dmem_preload.size() > config_pkg::DMEM_NUM_WORDS)  `uvm_fatal("SEQ/DMEM_OVERFLOW", "DMEM Overflow")

        if(sc_prf_preload.size() > config_pkg::ARCH_REG_DEPTH) `uvm_fatal("SEQ/REG_OVERFLOW", "Scalar registers overflow")
        if(vc_prf_preload.size() > config_pkg::ARCH_REG_DEPTH) `uvm_fatal("SEQ/REG_OVERFLOW", "Vector registers overflow")

        if(sc_prf_preload[0]!= 0) `uvm_warning("SEQ/INVALID_0_VAL", "non zero x0 value preload into scalar register")

        n_cycles = config_pkg::IMEM_NUM_WORDS; // same as DMEM_NUM_WORDS and always greater than ARCH_REG_DEPTH

        for(int unsigned i=0; i<n_cycles; i++) begin
            
            sc_reg_active = (i <sc_prf_preload.size()) && (i < config_pkg::ARCH_REG_DEPTH);
            vc_reg_active = (i <vc_prf_preload.size()) && (i < config_pkg::ARCH_REG_DEPTH);

            imem_data = (i < imem_preload.size()) ? imem_preload[i] : top_tb_config_pkg::TERMINATE; // pads with terminate instruction
            dmem_data = (i < dmem_preload.size()) ? dmem_preload[i] : '0;

            sc_prf_data = sc_reg_active ? sc_prf_preload[i] : '0;
            vc_prf_data = vc_reg_active ? vc_prf_preload[i] : '0;

            preload_single(

                .imem_en(1'b1),
                .imem_address(signal_pkg::imem_address_t'(i)),
                .imem_data(imem_data),

                .dmem_en(1'b1),
                .dmem_address(signal_pkg::dmem_word_address_t'(i)),
                .dmem_data(dmem_data),

                .sc_prf_en(sc_reg_active),
                .sc_prf_tag(signal_pkg::prf_address_t'(i)),
                .sc_prf_data(sc_prf_data),

                .vc_prf_en(vc_reg_active),
                .vc_prf_tag(signal_pkg::prf_address_t'(i)),
                .vc_prf_data(vc_prf_data)
            );
        end

        `uvm_info("SEQ","Preload complete", UVM_LOW)

    endtask : body

    protected task preload_single(

        input logic imem_en = 1'b0,
        input signal_pkg::imem_address_t imem_address = '0,
        input signal_pkg::data_t imem_data = '0,

        input logic dmem_en = 1'b0,
        input signal_pkg::dmem_word_address_t dmem_address = '0,
        input signal_pkg::vector_data_t dmem_data = '0,

        input logic sc_prf_en = 1'b0,
        input signal_pkg::prf_address_t sc_prf_tag = '0,
        input signal_pkg::data_t sc_prf_data = '0,

        input logic vc_prf_en = 1'b0,
        input signal_pkg::prf_address_t vc_prf_tag = '0,
        input signal_pkg::vector_data_t vc_prf_data = '0
        
    );

        top_tb_tr_preload req;

        req = top_tb_tr_preload::type_id::create("req");

        start_item(req);

        req.imem_en = imem_en;
        req.imem_address = imem_address;
        req.imem_data = imem_data;

        req.dmem_en = dmem_en;
        req.dmem_address = dmem_address;
        req.dmem_write_enable = {config_pkg::DMEM_NUM_BANKS{dmem_en}};
        req.dmem_data = dmem_data;

        req.sc_prf_en = sc_prf_en;
        req.sc_prf_address.tag = sc_prf_tag;
        req.sc_prf_address.vector = 1'b0;
        req.sc_prf_data = sc_prf_data;

        req.vc_prf_en = vc_prf_en;
        req.vc_prf_address.tag = vc_prf_tag;
        req.vc_prf_address.vector = 1'b1;
        req.vc_prf_data = vc_prf_data;

        finish_item(req);

    endtask : preload_single

endclass : top_tb_seq_preload