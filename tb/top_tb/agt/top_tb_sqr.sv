/*  -----------------------------------------------------------------------------------------------
 *                          Class for top-level system sequencer
 *  -----------------------------------------------------------------------------------------------
 *  <Todo: add additional documentation here>
 *  Base uvm_sequencer class is parameterized to accomodate both compute and preload transactions;
 *  use typecasting to choose
 *  Note: this class itself isnt parameterized, it extends a parameterized class
 */

class top_tb_sqr extends uvm_sequencer #(uvm_sequence_item);

    `uvm_component_utils(top_tb_sqr)

    function new(string name="top_tb_sqr", uvm_component parent=null);
        super.new(name,parent);
    endfunction : new

endclass : top_tb_sqr