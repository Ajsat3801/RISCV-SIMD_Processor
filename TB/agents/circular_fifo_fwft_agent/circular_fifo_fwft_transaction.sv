
class circular_fifo_fwft_transaction #(parameter type T = logic[31:0]) extends uvm_sequence_item;

    // Randomizable Fields
    rand T    push_data;
    rand bit  push;
    rand bit  pop;

    T data_out;
  	bit full;
  	bit empty;

    // Automation Macros
    `uvm_object_param_utils_begin(circular_fifo_fwft_transaction #(T))
        `uvm_field_int(push, UVM_ALL_ON)
        `uvm_field_int(pop, UVM_ALL_ON)
    `uvm_object_utils_end

    // Constructor
    function new(string name = "circular_fifo_fwft_transaction");
        super.new(name);
    endfunction

    // Constraints come here if any. No constraints in this case

    // virtual functions for push_data because not standard type
    // 5 functions used usually, print(), copy(), compare(), pack(), record()

    // appends data to printed output
    virtual function void do_print(uvm_printer printer); 
        super.do_print(printer);

        printer.print_generic(
            "push_data",
            "T",
            $bits(T),
            $sformatf("%h",push_data)
        );

        printer.print_generic(
            "data_out",
            "T",
            $bits(T),
            $sformatf("%h",data_out)
        );

    endfunction

    // if we do operand_a.copy(operand_b), deep copy of b assigned to a
    virtual function void do_copy(uvm_object rhs);
        circular_fifo_fwft_transaction #(T) rhs_;
      
      super.do_copy(rhs);

        if(!$cast(rhs_,rhs)) return;
        this.push_data = rhs_.push_data;
        this.data_out = rhs_.data_out;
        this.push = rhs_.push;
        this.pop = rhs_.pop;
      	this.full = rhs_.full;
      	this.empty = rhs_.empty;
    endfunction

endclass