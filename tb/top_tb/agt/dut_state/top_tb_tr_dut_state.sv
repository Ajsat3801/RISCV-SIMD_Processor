/*  -----------------------------------------------------------------------------------------------
 *                          Class for DUT state transaction object
 *  -----------------------------------------------------------------------------------------------
 *  Transaction to monitor current state of DUT
 *  <Todo: add additional documentation here>
 */

class top_tb_tr_dut_state extends uvm_sequence_item;

    /* --------------------------------------------------------------------------------------------
     * Declare UVM transaction elements 
     * --------------------------------------------------------------------------------------------
     */

    signal_pkg::data_t sc_reg_sample[config_pkg::ARCH_REG_DEPTH];
    bit sc_replicas_match;

    signal_pkg::vector_data_t vc_reg_sample[config_pkg::ARCH_REG_DEPTH];
    
    signal_pkg::data_t dmem_sample[config_pkg::DMEM_SIZE];

    /* --------------------------------------------------------------------------------------------
     * Utils & constraints
     * --------------------------------------------------------------------------------------------
     */

    `uvm_object_utils(top_tb_tr_dut_state)

    // constraints if any comes here

    /* --------------------------------------------------------------------------------------------
     * Constructor and virtual method overrides
     * --------------------------------------------------------------------------------------------
     */

    function new(string name="top_tb_tr_dut_state");
        super.new(name);
    endfunction

    function void do_copy(uvm_object rhs);
        
        top_tb_tr_dut_state rhs_;

        if(!$cast(rhs_, rhs)) begin
            `uvm_error("CAST ERROR", "Unable to cast rhs in do_copy")
            return;
        end

        super.do_copy(rhs);

        sc_reg_sample = rhs_.sc_reg_sample;
        sc_replicas_match = rhs_.sc_replicas_match;
        vc_reg_sample = rhs_.vc_reg_sample;
        dmem_sample = rhs_.dmem_sample;

        return;

    endfunction: do_copy

    function bit do_compare(uvm_object rhs, uvm_comparer comparer);

        top_tb_tr_dut_state rhs_;
        bit res = 1;

        if(!$cast(rhs_, rhs)) begin
            `uvm_error("CAST_ERROR", "Unable to cast rhs in do_compare")
            return 0;
        end

        res &= super.do_compare(rhs, comparer);
        res &= (sc_reg_sample == rhs_.sc_reg_sample);
        res &= (sc_replicas_match == rhs_.sc_replicas_match);
        res &= (vc_reg_sample == rhs_.vc_reg_sample);
        res &= (dmem_sample == rhs_.dmem_sample);

        return res;

    endfunction: do_compare
    
    function string convert2string();

        string s;
        s = super.convert2string();

        $sformat(s, "%s\n", s);
        $sformat(s, "%sScalar Registers:\n",s);

        for (int i = 0; i < config_pkg::ARCH_REG_DEPTH; i += 4) begin
            $sformat(s, "%sx%0d:%d\tx%0d:%d\tx%0d:%d\tx%0d:%d\n",
             s, i, sc_reg_sample[i], i+1, sc_reg_sample[i+1], i+2, sc_reg_sample[i+2], i+3, sc_reg_sample[i+3]);
        end

        if(sc_replicas_match) $sformat(s,"%sReplicas Match\n",s);
        else $sformat(s, "%sReplicas do not match\n", s);

        $sformat(s, "%s\nVector Registers:\n",s);

        for (int i = 0; i < config_pkg::ARCH_REG_DEPTH; i++) begin
            $sformat(s, "%sx%0d:%d %d %d %d\n",
             s, i, vc_reg_sample[i][0], vc_reg_sample[i][1], vc_reg_sample[i][2], vc_reg_sample[i][3]);
        end

        $sformat(s, "%s\nDMEM:\n",s);
        for (int i = 0; i < config_pkg::DMEM_SIZE; i += 8) begin
            $sformat(s, "%sx%0d:%d\tx%0d:%d\tx%0d:%d\tx%0d:%d\tx%0d:%d\tx%0d:%d\tx%0d:%d\tx%0d:%d\n",
             s, i, dmem_sample[i], i+1, dmem_sample[i+1], i+2, dmem_sample[i+2], i+3, dmem_sample[i+3],
             i+4, dmem_sample[i+4], i+5, dmem_sample[i+5], i+6, dmem_sample[i+6], i+7, dmem_sample[i+7]);
        end

        return s;

    endfunction: convert2string


endclass: top_tb_tr_dut_state