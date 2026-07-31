/*  -----------------------------------------------------------------------------------------------
 *                          Class for preload transaction object
 *  -----------------------------------------------------------------------------------------------
 *  <Todo: add additional documentation here>
 */

class top_tb_tr_preload extends uvm_sequence_item;

    /* --------------------------------------------------------------------------------------------
     * Declare UVM transaction elements 
     * --------------------------------------------------------------------------------------------
     */

    rand logic imem_en;
    rand signal_pkg::imem_address_t imem_address;
    rand signal_pkg::data_t imem_data;

    rand logic dmem_en;
    rand logic [config_pkg::DMEM_NUM_BANKS-1:0] dmem_write_enable;
    rand signal_pkg::dmem_address_t dmem_address;
    rand signal_pkg::vector_data_t dmem_data;

    rand logic sc_prf_en;
    rand signal_pkg::data_t sc_prf_data;
    rand signal_pkg::prf_tag_t sc_prf_address;

    rand logic vc_prf_en;
    rand signal_pkg::vector_data_t vc_prf_data;
    rand signal_pkg::prf_tag_t vc_prf_address;

    /* --------------------------------------------------------------------------------------------
     * Utils & constraints
     * --------------------------------------------------------------------------------------------
     */

    `uvm_object_utils(top_tb_tr_preload)

    // constraints if any comes here

    /* --------------------------------------------------------------------------------------------
     * Constructor and virtual method overrides
     * --------------------------------------------------------------------------------------------
     */

    function new(string name="top_tb_tr_preload");
        super.new(name);
    endfunction

    // virtual method overrides

    function void do_copy(uvm_object rhs);
        
        top_tb_tr_preload rhs_;
        
        if(!$cast(rhs_, rhs)) begin // perform type cast
            `uvm_error("CAST_ERROR","Unable to perform type casting in do_copy")
            return;
        end

        super.do_copy(rhs);

        imem_en = rhs_.imem_en;
        imem_address = rhs_.imem_address;
        imem_data = rhs_.imem_data;

        dmem_en = rhs_.dmem_en;
        dmem_write_enable = rhs_.dmem_write_enable;
        dmem_address = rhs_.dmem_address;
        dmem_data = rhs_.dmem_data;

        sc_prf_en = rhs_.sc_prf_en;
        sc_prf_data = rhs_.sc_prf_data;
        sc_prf_address = rhs_.sc_prf_address;

        vc_prf_en = rhs_.vc_prf_en;
        vc_prf_data = rhs_.vc_prf_data;
        vc_prf_address = rhs_.vc_prf_address;

        return;


    endfunction: do_copy

    function bit do_compare(uvm_object rhs, uvm_comparer comparer);

        top_tb_tr_preload rhs_;
        bit res = 1'b1;

        if(!$cast(rhs_, rhs)) begin
            `uvm_error("CAST_ERROR", "Unable to perform type casting in do_compare")
            return 0;
        end

        res &= super.do_compare(rhs, comparer);

        res &= (imem_en == rhs_.imem_en);
        res &= (imem_address == rhs_.imem_address);
        res &= (imem_data == rhs_.imem_data);

        res &= (dmem_en == rhs_.dmem_en);
        res &= (dmem_write_enable == rhs_.dmem_write_enable);
        res &= (dmem_address == rhs_.dmem_address);
        res &= (dmem_data == rhs_.dmem_data);

        res &= (sc_prf_en == rhs_.sc_prf_en);
        res &= (sc_prf_data == rhs_.sc_prf_data);
        res &= (sc_prf_address == rhs_.sc_prf_address);

        res &= (vc_prf_en == rhs_.vc_prf_en);
        res &= (vc_prf_data == rhs_.vc_prf_data);
        res &= (vc_prf_address == rhs_.vc_prf_address);

        return res;
        

    endfunction: do_compare

    function string convert2string();

        string s;
        s = super.convert2string();

        $sformat(s, "%s\n", s);

        $sformat(s, "%s imem [%0b (%0h) @ %0d] | dmem [%0b %0b (%0h) @ %0d]\n",
                s, imem_en, imem_data, imem_address, dmem_en, dmem_write_enable, dmem_data, dmem_address);

        $sformat(s, "%s sc_prf [%0b (%0h) @ %0d] | vc_prf [%0b (%0h) @ %0d]",
                s, sc_prf_en, sc_prf_data, sc_prf_address, vc_prf_en, vc_prf_data, vc_prf_address);

        return s;

    endfunction: convert2string


endclass : top_tb_tr_preload