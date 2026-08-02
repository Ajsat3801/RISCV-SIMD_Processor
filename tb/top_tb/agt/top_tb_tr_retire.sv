/*  -----------------------------------------------------------------------------------------------
 *                          Class for retirement snapshot transaction object
 *  -----------------------------------------------------------------------------------------------
 *  <Todo: add additional documentation here>
 */

class top_tb_tr_retire extends uvm_sequence_item;

    /* --------------------------------------------------------------------------------------------
     * Declare UVM transaction elements 
     * --------------------------------------------------------------------------------------------
     */

    top_tb_typedef_pkg::retire_snapshot_t snapshot;

    /* --------------------------------------------------------------------------------------------
     * Utils & constraints
     * --------------------------------------------------------------------------------------------
     */

    `uvm_object_utils(top_tb_tr_retire)

    // constraints if any comes here

    /* --------------------------------------------------------------------------------------------
     * Constructor and virtual method overrides
     * --------------------------------------------------------------------------------------------
     */

    function new(string name="top_tb_tr_retire");
        super.new(name);
    endfunction : new

    // virtual method overrides

    function void do_copy(uvm_object rhs);

        top_tb_tr_retire rhs_;

        if(!$cast(rhs_, rhs)) begin
            `uvm_error("CAST_ERROR","Unable to perform type casting in do_copy")
            return;
        end

        super.do_copy(rhs);

        snapshot = rhs_.snapshot;

    endfunction: do_copy

    function bit do_compare(uvm_object rhs, uvm_comparer comparer);

        top_tb_tr_retire rhs_;
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

        $sformat(s, "%s\n valid:%0b prf_tag:%0h rob_id:%0h data:%0h wr:%0b dest:%0h branch:%0b taken:%0b\n",
            s, snapshot.valid, snapshot.prf_tag, snapshot.rob_id, snapshot.data,
            snapshot.write_to_reg, snapshot.dest_address, snapshot.is_branch, snapshot.branch_taken);

        return s;
    endfunction: convert2string

endclass : top_tb_tr_retire