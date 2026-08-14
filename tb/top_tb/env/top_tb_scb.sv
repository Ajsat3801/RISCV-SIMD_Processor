
`uvm_analysis_imp_decl(_preload)
`uvm_analysis_imp_decl(_compute)
`uvm_analysis_imp_decl(_dut_state)

class top_tb_scb extends uvm_scoreboard;

    `uvm_component_utils(top_tb_scb)

    uvm_analysis_imp_preload #(top_tb_tr_preload, top_tb_scb) imp_preload;
    uvm_analysis_imp_compute #(top_tb_tr_compute, top_tb_scb) imp_compute;
    uvm_analysis_imp_dut_state #(top_tb_tr_dut_state, top_tb_scb) imp_dut_state;

    top_tb_ref_model_adapter ref_model;

    int unsigned no_preload;
    int unsigned no_compute;
    int unsigned no_dut_state;
    int unsigned no_mismatch;

    function new(string name ="top_tb_scb", uvm_component parent=null);
        super.new(name, parent);
    endfunction : new

    //  -------------------------------------------------------------------------------------------
    //                                Phases and analysis port writes
    //  -------------------------------------------------------------------------------------------

    virtual function void build_phase (uvm_phase phase);
        
        super.build_phase(phase);

        imp_preload = new("imp_preload", this);
        imp_compute = new("imp_compute", this);
        imp_dut_state = new("imp_dut_state", this);

        ref_model = new();
        ref_model.create_model();

        no_preload = 0;
        no_compute = 0;
        no_dut_state = 0;
        no_mismatch = 0;

    endfunction : build_phase

    virtual function void check_phase (uvm_phase phase);

        // tests to see if checking actually happened. the actual functional verification done
        // in the analysis port writes

        super.check_phase(phase);

        if(no_preload == 0) `uvm_error( "SCB/NO_PRELOAD","No preload transactions observed")
        if(no_compute == 0) `uvm_error( "SCB/NO_COMPUTE", "No compute asserted")
        if(no_dut_state == 0) `uvm_error("SCB/NO_SNAPSHOT", "No final state snapshot found")
        else if(no_dut_state != 1) `uvm_error("SCB/EXCESS_SNAPSHOT", "Received more than 1 final state snapshot")

        `uvm_info("SCB/SUMMARY",
                $sformatf("preloads:%0d | computes:%0d | snapshots:%0d | mismatches:%0d", 
                            no_preload, no_compute, no_dut_state, no_mismatch), 
                UVM_LOW);

    endfunction : check_phase

    virtual function void write_preload(top_tb_tr_preload tr);
        // runs when top_tb_mon_preload calls ap.write()

        ref_model.preload(tr);
        `uvm_info("SCB", $sformatf("Preload forwarded to ref model: %s", tr.convert2string()), UVM_DEBUG)

        no_preload++;

    endfunction : write_preload

    virtual function void write_compute(top_tb_tr_compute tr);
        // placeholder function, does nothing currently
        // will be useful for future implementation to check retirement bus locksteps

        no_compute++;

    endfunction : write_compute

    virtual function void write_dut_state(top_tb_tr_dut_state tr);
        // this is the function that does all the scoreboard stuff

        signal_pkg::data_t sc_reg_res[config_pkg::ARCH_REG_DEPTH];
        signal_pkg::vector_data_t vc_reg_res[config_pkg::ARCH_REG_DEPTH];
        signal_pkg::data_t dmem_res[config_pkg::DMEM_SIZE];

        int unsigned sc_regs_mismatches, vc_regs_mismatches, dmem_mismatches;
        bit sc_regs_pass, vc_regs_pass, dmem_pass;

        ref_model.simulate(sc_reg_res, vc_reg_res, dmem_res);

        `uvm_info(  "SCB",
                    "DUT final state snapshot received, comparing against ref model",
                    UVM_MEDIUM )

        sc_regs_mismatches = compare_sc_regs(tr, sc_reg_res);
        vc_regs_mismatches = compare_vc_regs(tr, vc_reg_res);
        dmem_mismatches = compare_dmem(tr, dmem_res);

        sc_regs_pass = (sc_regs_mismatches == 0);
        vc_regs_pass = (vc_regs_mismatches == 0);
        dmem_pass    = (dmem_mismatches == 0);

        if(sc_regs_pass) `uvm_info("SCB_RESULT", "Scalar Register snapshot match golden reference", UVM_LOW)
        if(vc_regs_pass) `uvm_info("SCB_RESULT", "Vector Register snapshot match golden reference", UVM_LOW)
        if(dmem_pass) `uvm_info("SCB_RESULT", "DMEM snapshot match golden reference", UVM_LOW)

        if(sc_regs_pass && vc_regs_pass && dmem_pass) `uvm_info("SCB_RESULT", "Test passed", UVM_LOW)

        no_dut_state++;
        no_mismatch += sc_regs_mismatches + vc_regs_mismatches + dmem_mismatches;

    endfunction : write_dut_state

    //  -------------------------------------------------------------------------------------------
    //                                   Wrapper functions
    //  -------------------------------------------------------------------------------------------

    function int unsigned compare_sc_regs(
        top_tb_tr_dut_state tr,
        signal_pkg::data_t sc_reg_res[config_pkg::ARCH_REG_DEPTH]
    );
        int unsigned mismatches = 0;
        for(int i=0; i<config_pkg::ARCH_REG_DEPTH; i++) begin
            if(tr.sc_reg_sample[i]!= sc_reg_res[i]) begin
                mismatches++;
                `uvm_error( "SCB/SC_REG_MISMATCH",
                            $sformatf(  "Mismatch @ idx: %d\texp:%h\tact:%h",
                                        i, sc_reg_res[i], tr.sc_reg_sample[i])
                )
            end
        end

        return mismatches;

    endfunction : compare_sc_regs

    function int unsigned compare_vc_regs(
        top_tb_tr_dut_state tr,
        signal_pkg::vector_data_t vc_reg_res[config_pkg::ARCH_REG_DEPTH]
    );

        int unsigned mismatches = 0;

        for(int i=0; i<config_pkg::ARCH_REG_DEPTH; i++) begin
            if(tr.vc_reg_sample[i] != vc_reg_res[i]) begin
                mismatches++;
                `uvm_error( "SCB/VC_REG_MISMATCH",
                            $sformatf(  "Mismatch @ idx: %d\texp:%h %h %h %h\tact:%h %h %h %h",
                                        i, vc_reg_res[i][0], vc_reg_res[i][1], vc_reg_res[i][2],
                                        vc_reg_res[i][3], tr.vc_reg_sample[i][0],
                                        tr.vc_reg_sample[i][1], tr.vc_reg_sample[i][2],
                                        tr.vc_reg_sample[i][3])
                )
            end
        end

        return mismatches;

    endfunction : compare_vc_regs

    function int unsigned compare_dmem(
        top_tb_tr_dut_state tr,
        signal_pkg::data_t dmem_res[config_pkg::DMEM_SIZE]
    );

        int unsigned mismatches = 0;

        for(int i=0; i<config_pkg::DMEM_SIZE; i++) begin
            if(tr.dmem_sample[i] != dmem_res[i]) begin
                mismatches++;
                `uvm_error( "SCB/DMEM_MISMATCH",
                            $sformatf(  "Mismatch @ idx: %d\texp:%h\tact:%h",
                                        i, dmem_res[i], tr.dmem_sample[i])
                )
            end
        end

        return mismatches;

    endfunction : compare_dmem

endclass : top_tb_scb