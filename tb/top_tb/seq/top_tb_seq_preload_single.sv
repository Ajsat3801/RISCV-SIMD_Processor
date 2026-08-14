
class top_tb_seq_preload_single extends top_tb_seq_base;

    `uvm_object_utils(top_tb_seq_preload_single)

    logic imem_en;
    signal_pkg::imem_address_t imem_address;
    signal_pkg::data_t imem_data;

    logic dmem_en;
    signal_pkg::dmem_word_address_t dmem_address;

    logic sc_prf_en;
    signal_pkg::prf_address_t sc_prf_tag;

    logic vc_prf_en;
    signal_pkg::prf_address_t vc_prf_tag;

    function new(string name="top_tb_seq_preload_single");
        
        super.new(name);

        imem_en = 1'b0;
        imem_address = '0;
        imem_data = '0;

        dmem_en = 1'b0;
        dmem_address = '0;

        sc_prf_en = 1'b0;
        sc_prf_tag = '0;

        vc_prf_en = 1'b0;
        vc_prf_tag   = '0;

    endfunction : new

    virtual task body();

        top_tb_tr_preload req;

        req = top_tb_tr_preload::type_id::create("req");

        start_item(req);

        req.imem_en = imem_en;
        req.imem_address = imem_address;
        req.imem_data = imem_data;

        req.dmem_en = dmem_en;
        req.dmem_address = dmem_address;
        req.dmem_write_enable = {config_pkg::DMEM_NUM_BANKS{1'b1}};

        req.sc_prf_en = sc_prf_en;
        req.sc_prf_address.tag = sc_prf_tag;
        req.sc_prf_address.vector = 1'b0;   // adapter casts the whole struct to int - see note

        req.vc_prf_en = vc_prf_en;
        req.vc_prf_address.tag = vc_prf_tag;
        req.vc_prf_address.vector = 1'b0;

        if(!req.randomize(dmem_data, sc_prf_data, vc_prf_data)) 
            `uvm_error("SEQ/RAND", "randomization failed for top_tb_tr_preload")

        finish_item(req);

    endtask : body

    task preload_single(
        input uvm_sequencer_base sqr,
        input uvm_sequence_base parent = null,

        input logic imem_en = 1'b0,
        input signal_pkg::imem_address_t imem_address = '0,
        input signal_pkg::data_t imem_data    = '0,

        input logic dmem_en = 1'b0,
        input signal_pkg::dmem_word_address_t dmem_address = '0,

        input logic sc_prf_en = 1'b0,
        input signal_pkg::prf_address_t sc_prf_tag = '0,

        input logic vc_prf_en = 1'b0,
        input signal_pkg::prf_address_t vc_prf_tag = '0
    );

        this.imem_en = imem_en;
        this.imem_address = imem_address;
        this.imem_data = imem_data;

        this.dmem_en = dmem_en;
        this.dmem_address = dmem_address;

        this.sc_prf_en = sc_prf_en;
        this.sc_prf_tag = sc_prf_tag;

        this.vc_prf_en = vc_prf_en;
        this.vc_prf_tag = vc_prf_tag;

        this.start(sqr, parent);

    endtask : preload_single

endclass : top_tb_seq_preload_single