`uvm_analysis_imp_decl(_alloc)
`uvm_analysis_imp_decl(_retire)

class top_tb_cov extends uvm_component;

    `uvm_component_utils(top_tb_cov)

    uvm_analysis_imp_alloc #(top_tb_tr_alloc, top_tb_cov) imp_alloc;
    uvm_analysis_imp_retire #(top_tb_tr_retire, top_tb_cov) imp_retire;

    covergroup cg_instr with function sample(top_tb_typedef_pkg::instr_e id);

        option.per_instance = 1;
        option.name = "cg_instr";
        cp_id: coverpoint id;

    endgroup

    covergroup cg_operand with function sample(
        bit src1_valid, bit src1_is_vector,
        pkg_instruction_decoding::sc_operand_bin_e sc_src1, pkg_instruction_decoding::vc_operand_bin_e vc_src1,
        bit src2_valid, bit src2_is_vector,
        pkg_instruction_decoding::sc_operand_bin_e sc_src2, pkg_instruction_decoding::vc_operand_bin_e vc_src2
    );

        option.per_instance = 1;
        option.name = "cg_operand";
        cp_sc_src1 : coverpoint sc_src1 iff (src1_valid && !src1_is_vector);
        cp_sc_src2 : coverpoint sc_src2 iff (src2_valid && !src2_is_vector);
        cross_sc : cross cp_sc_src1, cp_sc_src2 iff (src1_valid && !src1_is_vector && src2_valid && !src2_is_vector);

        cp_vc_src1 : coverpoint vc_src1 iff (src1_valid && src1_is_vector);
        cp_vc_src2 : coverpoint vc_src2 iff (src2_valid && src2_is_vector);

    endgroup

    top_tb_typedef_pkg::alloc_snapshot_t alloc_buf[config_pkg::ROB_DEPTH];
    bit alloc_buf_populated[config_pkg::ROB_DEPTH];

    int unsigned num_alloc;
    int unsigned num_retired_matched;
    int unsigned num_evicted_unretired;

    // file handles for instr and operand csv files
    //int fd_instr;
    int fd_operand;

    function new(string name="top_tb_cov", uvm_component parent = null);
        super.new(name, parent);
        cg_instr = new();
        cg_operand = new();
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        imp_alloc  = new("imp_alloc", this);
        imp_retire = new("imp_retire", this);

        foreach(alloc_buf_populated[i]) alloc_buf_populated[i] = 1'b0;

        num_alloc = 0;
        num_retired_matched = 0;
        num_evicted_unretired = 0;

        fd_operand = $fopen($sformatf("cov_trace_seed%0d.csv", $get_initial_random_seed()), "w");
        $fwrite(fd_operand, "time,instr_id,src1_bin,src2_bin\n");

    endfunction : build_phase

    virtual function void write_alloc(top_tb_tr_alloc t);
        // transaction that snoops alloc bus, this will show if an instruction was allocated to the ROB

        int unsigned addr;
        addr = t.snapshot.rob_id.address;

        if(alloc_buf_populated[addr])
            num_evicted_unretired++;   // this address's previous occupant never retired -> flushed

        alloc_buf[addr] = t.snapshot;
        alloc_buf_populated[addr] = 1'b1;
        num_alloc++;

    endfunction : write_alloc

    virtual function void write_retire(top_tb_tr_retire t);

        int unsigned addr;
        top_tb_typedef_pkg::alloc_snapshot_t snap;
        top_tb_typedef_pkg::instr_e id;
        bit src1_vld, src2_vld;
        pkg_instruction_decoding::sc_operand_bin_e sc1, sc2;
        pkg_instruction_decoding::vc_operand_bin_e vc1, vc2;

        if(!t.snapshot.valid) return;

        addr = t.snapshot.rob_id.address;

        if(!alloc_buf_populated[addr]) begin
            `uvm_warning("COV/NO_ALLOC_SNAPSHOT",
                $sformatf("Retirement for rob_id addr=%0d had no buffered alloc snapshot", addr))
            return;
        end

        snap = alloc_buf[addr];

        if(snap.rob_id.epoch !== t.snapshot.rob_id.epoch)
            `uvm_error("COV/EPOCH_MISMATCH",
                $sformatf("Buffered alloc epoch %0b != retiring epoch %0b at addr=%0d — buffer logic bug",
                    snap.rob_id.epoch, t.snapshot.rob_id.epoch, addr))

        alloc_buf_populated[addr] = 1'b0;
        num_retired_matched++;

        id = pkg_instruction_decoding::classify_instr(snap.chip_select, snap.operation, snap.read_src2,
                                                  snap.is_branch, snap.src1_vector);

        src1_vld = (snap.chip_select != signal_pkg::NONE);
        src2_vld = pkg_instruction_decoding::src2_valid(snap.chip_select, snap.operation, snap.read_src2);

        sc1 = pkg_instruction_decoding::classify_sc_operand(snap.src1_address);
        vc1 = pkg_instruction_decoding::classify_vc_operand(snap.src1_address);
        sc2 = pkg_instruction_decoding::classify_sc_operand(snap.src2_address);
        vc2 = pkg_instruction_decoding::classify_vc_operand(snap.src2_address);

        cg_instr.sample(id);
        cg_operand.sample(src1_vld, snap.src1_vector, sc1, vc1,
                           src2_vld, snap.src2_vector, sc2, vc2);

        $fwrite(fd_operand, "%0t,%s,%s,%s\n", $time, id.name(),
            operand_bin_str(src1_vld, snap.src1_vector, sc1, vc1),
            operand_bin_str(src2_vld, snap.src2_vector, sc2, vc2));
        $fflush(fd_operand);   // cheap insurance against a truncated file on uvm_fatal/timeout exit

    endfunction : write_retire

    virtual function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        `uvm_info("COV/SUMMARY",
            $sformatf("allocs:%0d retired_matched:%0d evicted_unretired(flushed):%0d",
                num_alloc, num_retired_matched, num_evicted_unretired), UVM_LOW)
    endfunction : report_phase

    virtual function void final_phase(uvm_phase phase);
        super.final_phase(phase);
        $fclose(fd_operand);
    endfunction : final_phase

    function automatic string operand_bin_str(
        bit vld, bit vec, pkg_instruction_decoding::sc_operand_bin_e sc, pkg_instruction_decoding::vc_operand_bin_e vc
    );
        if(!vld) return "NA";
        else if(vec) return vc.name();
        else return sc.name();
    endfunction


endclass : top_tb_cov