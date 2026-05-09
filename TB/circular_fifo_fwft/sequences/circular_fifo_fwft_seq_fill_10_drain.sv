
class lib_fifo_fwft_1push_seq_fill_10_drain extends lib_fifo_fwft_1push_base_seq;

    `uvm_object_param_utils(lib_fifo_fwft_1push_seq_fill_10_drain)

    function new(string name = "lib_fifo_fwft_1push_seq_fill_10_drain");
        super.new(name);
    endfunction

    task generate_seq();

        lib_fifo_fwft_1push_tr tr;

        repeat(BUFFER_SIZE) begin
            tr = lib_fifo_fwft_1push_tr::type_id::create("tr");
            
            start_item(tr);
            if (!tr.randomize()) `uvm_fatal("SEQ","transaction randomization failed")

            tr.push = 1'b1;
            tr.pop = 1'b0;

            finish_item(tr);
        end

        repeat(10) begin
            tr = lib_fifo_fwft_1push_tr::type_id::create("tr");

            start_item(tr);
            if (!tr.randomize()) `uvm_fatal("SEQ","transaction randomization failed")
            finish_item(tr);
        end

        repeat(BUFFER_SIZE) begin
            tr = lib_fifo_fwft_1push_tr::type_id::create("tr");

            start_item(tr);
            if(!tr.randomize()) `uvm_fatal("SEQ","transaction randomization failed")

            tr.push = 1'b0;
            tr.pop = 1'b1;

            finish_item(tr);
        end

        `uvm_info("SEQ","Sequence complete", UVM_HIGH)

    endtask

endclass