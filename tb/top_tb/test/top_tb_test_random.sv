
class top_tb_test_random extends top_tb_test_base;

    `uvm_component_utils(top_tb_test_random)

    function new(string name = "top_tb_test_random", uvm_component parent = null);
        super.new(name, parent);
    endfunction : new

    virtual function void create_sequence();
        seq = top_tb_seq_random_tb::type_id::create("seq");
    endfunction : create_sequence

endclass : top_tb_test_random