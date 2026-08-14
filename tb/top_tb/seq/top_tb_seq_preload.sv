
class top_tb_seq_preload extends top_tb_seq_base;

    `uvm_object_utils(top_tb_seq_preload)

    signal_pkg::data_t imem_program[];

    top_tb_seq_preload_single seq_single;

    function new(string name="top_tb_seq_preload");
        super.new(name);
    endfunction

    virtual task body();

        int unsigned n_cycles;
        logic imem_active, dmem_active, reg_active;
        signal_pkg::data_t instr_word;
        
        if(imem_program.size() == 0) `uvm_fatal("SEQ/NOPROGRAM","Imem preload program empty")
        if(imem_program.size() > config_pkg::IMEM_NUM_WORDS) `uvm_fatal("SEQ/IMEM_OVERLOW", "Imem overflow")
        if(top_tb_config_pkg::DMEM_FILL_UPTO > config_pkg::DMEM_NUM_WORDS) 
            `uvm_fatal("SEQ/DMEM_OVERFLOW", "DMEM Overflow")

        seq_single = top_tb_seq_preload_single::type_id::create("seq_single");

        n_cycles = top_tb_config_pkg::DMEM_FILL_UPTO;
        if(imem_program.size()>n_cycles) n_cycles = imem_program.size();
        if(config_pkg::ARCH_REG_DEPTH>n_cycles) n_cycles = config_pkg::ARCH_REG_DEPTH;

        for(int unsigned i=0; i<n_cycles; i++) begin
            imem_active = (i < imem_program.size());
            dmem_active = (i < top_tb_config_pkg::DMEM_FILL_UPTO);
            reg_active = (i>=1) && (i<config_pkg::ARCH_REG_DEPTH);
            instr_word = imem_active ? imem_program[i] : '0;

            seq_single.preload_single(
                .sqr(m_sequencer),
                .parent(this),
                .imem_en(imem_active),
                .imem_address(signal_pkg::imem_address_t'(i)),
                .imem_data(instr_word),
                .dmem_en(dmem_active),
                .dmem_address(signal_pkg::dmem_word_address_t'(i)),
                .sc_prf_en(reg_active),
                .sc_prf_tag(signal_pkg::prf_address_t'(i)),
                .vc_prf_en(reg_active),
                .vc_prf_tag(signal_pkg::prf_address_t'(i))
            );
        end

        `uvm_info("SEQ","Preload complete", UVM_LOW)

    endtask : body

endclass : top_tb_seq_preload