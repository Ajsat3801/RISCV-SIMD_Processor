
class circular_fifo_fwft_sequence_fill_10_drain extends circular_fifo_fwft_base_sequence;

    `uvm_object_param_utils(circular_fifo_fwft_sequence_fill_10_drain)

    function new(string name = "circular_fifo_fwft_sequence_fill_10_drain");
        super.new(name);
    endfunction

    task generate_sequence();

        circular_fifo_fwft_transaction tr;

        repeat(BUFFER_SIZE) begin
            tr = circular_fifo_fwft_transaction::type_id::create("tr");
            
            start_item(tr);
            if (!tr.randomize()) `uvm_fatal("SEQ","transaction randomization failed")

            tr.push = 1'b1;
            tr.pop = 1'b0;

            finish_item(tr);
        end

        repeat(10) begin
            tr = circular_fifo_fwft_transaction::type_id::create("tr");

            start_item(tr);
            if (!tr.randomize()) `uvm_fatal("SEQ","transaction randomization failed")
            finish_item(tr);
        end

        repeat(BUFFER_SIZE) begin
            tr = circular_fifo_fwft_transaction::type_id::create("tr");

            start_item(tr);
            if(!tr.randomize()) `uvm_fatal("SEQ","transaction randomization failed")

            tr.push = 1'b0;
            tr.pop = 1'b1;

            finish_item(tr);
        end

        `uvm_info("SEQ","Sequence complete", UVM_HIGH)

    endtask

endclass