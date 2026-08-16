class top_tb_seq_base extends uvm_sequence #(top_tb_tr_base);

    `uvm_object_utils(top_tb_seq_base)

    function new(string name="top_tb_seq_base");
        super.new(name);
    endfunction : new

    // No body because this class will never be started on its own

endclass : top_tb_seq_base