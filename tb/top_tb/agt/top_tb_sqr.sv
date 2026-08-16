/*  -----------------------------------------------------------------------------------------------
 *                          Class for top-level system sequencer
 *  -----------------------------------------------------------------------------------------------
 *  <Todo: add additional documentation here>
 */

class top_tb_sqr extends uvm_sequencer #(top_tb_tr_base);

    `uvm_component_utils(top_tb_sqr)

    function new(string name="top_tb_sqr", uvm_component parent=null);
        super.new(name,parent);
    endfunction : new

endclass : top_tb_sqr