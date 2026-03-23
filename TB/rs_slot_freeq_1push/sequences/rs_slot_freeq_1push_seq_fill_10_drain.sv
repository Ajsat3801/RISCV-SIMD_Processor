
class rs_slot_freeq_1input_seq_fill_10_drain
extends rs_slot_freeq_1input_base_seq;

    `uvm_object_utils(rs_slot_freeq_1input_seq_fill_10_drain)

    function new(name="rs_slot_freeq_1input_seq_fill_10_drain")
        super.new(name);
    endfunction

    task generate_seq();

        rs_slot_freeq_1input_tr tr;

        repeat(BUFFER_SIZE) begin
            
            start_item();
            tr = rs_slot_freeq_1input_tr::type_id::create("tr");
            if(!tr.randomize()) `uvm_fatal("SEQ", "Sequence randomization failed");

            tr.push = 1'b1;
            tr.pop = 1'b0;

            finish_item()
        end
        
        repeat(10) begin
            tr = rs_slot_freeq_1input_tr::type_id::create("tr");

            start_item();
            if(!tr.randomize) `uvm_fatal("SEQ", "Sequence Randomization failed");
            finish_item();
        end

        repeat(BUFFER_SIZE) begin
            tr = rs_slot_freeq_1input_tr::type_id::create("tr");

            start_item();
            if(!tr.randomize()) `uvm_fatal("SEQ", "Sequence randomization failed")
            
            tr.push = 1'b0;
            tr.pop = 1'b1;
            finish_item();
        end
        

    endtask


endclass