class top_tb_test_sanity_check_directed extends top_tb_test_base;

    `uvm_component_utils(top_tb_test_sanity_check_directed)

    function new(string name = "top_tb_test_sanity_check_directed", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void create_sequence();
        seq = top_tb_seq_sanity_check_directed_tb::type_id::create("seq");
    endfunction : create_sequence

endclass : top_tb_test_sanity_check_directed