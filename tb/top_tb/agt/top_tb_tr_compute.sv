/*  -----------------------------------------------------------------------------------------------
 *                          Class for compute transaction object
 *  -----------------------------------------------------------------------------------------------
 *  Transaction for propogating control signal to enable or disable computes
 *  Note: only one of top_tb_tr_compute or top_tb_tr_preload transactions must fire at a time
 *  <Todo: add additional documentation here>
 */

class top_tb_tr_compute extends uvm_sequence_item;

    /* --------------------------------------------------------------------------------------------
     * Declare UVM transaction elements 
     * --------------------------------------------------------------------------------------------
     */
    
    bit start; // 1 = start_compute(), 0 = stop_compute()

    /* --------------------------------------------------------------------------------------------
     * Utils & constraints
     * --------------------------------------------------------------------------------------------
     */

    `uvm_object_utils(top_tb_tr_compute)

    function new(string name="top_tb_tr_compute");
        super.new(name);
    endfunction

    // constraints if any comes here

    /* --------------------------------------------------------------------------------------------
     * Constructor and virtual method overrides
     * --------------------------------------------------------------------------------------------
     */

    function void do_copy(uvm_object rhs);

        top_tb_tr_compute rhs_;

        if(!$cast(rhs_, rhs)) begin // perform type cast
            `uvm_error("CAST_ERROR","Unable to perform type casting in do_copy")
            return;
        end

        super.do_copy(rhs);

        start = rhs_.start;

    endfunction: do_copy

    function bit do_compare(uvm_object rhs, uvm_comparer comparer);

        top_tb_tr_compute rhs_;
        bit res = 1'b1;

        if(!$cast(rhs_, rhs)) begin
            `uvm_error("CAST_ERROR", "Unable to perform type casting in do_compare")
            return 0;
        end

        res &= super.do_compare(rhs, comparer);
        res &= (start == rhs_.start);

        return res;

    endfunction: do_compare

    function string convert2string();
        string s;
        s = super.convert2string();

        $sformat(s, "%s\n start \t%0b\n", s, start);

        return s;
    endfunction: convert2string

endclass : top_tb_tr_compute
