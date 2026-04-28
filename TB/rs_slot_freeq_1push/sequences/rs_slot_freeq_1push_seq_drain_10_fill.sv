
class lib_rs_slot_freeq_1push_seq_drain_10_fill extends lib_rs_slot_freeq_1push_base_seq;

        `uvm_object_utils(lib_rs_slot_freeq_1push_seq_drain_10_fill)

        function new(string name ="lib_rs_slot_freeq_1push_seq_drain_10_fill");
            super.new(name);
        endfunction

        task generate_seq();
            lib_rs_slot_freeq_1push_tr tr;

            repeat(BUFFER_SIZE) begin
                tr = lib_rs_slot_freeq_1push_tr::type_id::create("tr");

                start_item(tr);

                if(!tr.randomize()) `uvm_fatal("SEQ","Transaction randomization failed")

                tr.push = 1'b0;
                tr.pop = 1'b1;

                finish_item(tr);
            end

            repeat(10) begin
                tr = lib_rs_slot_freeq_1push_tr::type_id::create("tr");

                start_item(tr);
                if(!tr.randomize()) `uvm_fatal("SEQ","tansaction randomization failed")
                finish_item(tr);

            end

            repeat(BUFFER_SIZE) begin
                tr = lib_rs_slot_freeq_1push_tr::type_id::create("tr");

                start_item(tr);
                if(!tr.randomize()) `uvm_fatal("SEQ","transaction randomization failed")

                tr.push = 1'b1;
                tr.pop = 1'b0;

                finish_item(tr);
            end

        endtask

endclass