class top_tb_seq_compute extends top_tb_seq_base;

    `uvm_object_utils(top_tb_seq_compute)

    bit compute;

    function new(string name="top_tb_seq_compute");
        super.new(name);
        compute = 1'b1;
    endfunction : new

    virtual task body();

        top_tb_tr_compute req;

        req = top_tb_tr_compute::type_id::create("req");

        start_item(req);
        req.start = compute;
        finish_item(req);

    endtask : body

    task start_compute(
        input uvm_sequencer_base sqr,
        input uvm_sequence_base parent = null
    );
        
        compute = 1'b1;
        this.start(sqr, parent);

    endtask : start_compute

    task halt_compute(
        input uvm_sequencer_base sqr,
        input uvm_sequence_base parent = null
    );
        
        compute = 1'b0;
        this.start(sqr, parent);

    endtask : halt_compute


endclass : top_tb_seq_compute