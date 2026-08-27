class top_tb_tr_alloc extends uvm_sequence_item;

    top_tb_typedef_pkg::alloc_snapshot_t snapshot;

    `uvm_object_utils(top_tb_tr_alloc)

    function new(string name="top_tb_tr_alloc");
        super.new(name);
    endfunction : new

    function void do_copy(uvm_object rhs);

        top_tb_tr_alloc rhs_;

        if(!$cast(rhs_, rhs)) begin
            `uvm_error("CAST_ERROR","Unable to perform type casting in do_copy")
            return;
        end

        super.do_copy(rhs);
        snapshot = rhs_.snapshot;

    endfunction: do_copy

    function bit do_compare(uvm_object rhs, uvm_comparer comparer);

        top_tb_tr_alloc rhs_;
        bit res = 1'b1;

        if(!$cast(rhs_, rhs)) begin
            `uvm_error("CAST_ERROR", "Unable to perform type casting in do_compare")
            return 0;
        end

        res &= super.do_compare(rhs, comparer);
        res &= (snapshot == rhs_.snapshot);

        return res;

    endfunction: do_compare

    function string convert2string();
        string s;
        s = super.convert2string();

        $sformat(s, "%svalid:%0b rob_id:%0h cs:%s op:%0h rd:%0d rs1:%0d rs2:%0d",
            s, snapshot.valid, snapshot.rob_id, snapshot.chip_select.name(), snapshot.operation,
            snapshot.dest_address, snapshot.src1_address, snapshot.src2_address);

        return s;
    endfunction: convert2string

endclass : top_tb_tr_alloc