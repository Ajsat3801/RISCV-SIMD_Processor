
class top_tb_seq_random_tb extends top_tb_seq_program_base;

    `uvm_object_utils(top_tb_seq_random_tb)

    rand int unsigned n_instr;

    int unsigned n_instr_min = 16;
    int unsigned n_instr_max = config_pkg::IMEM_NUM_WORDS;

    constraint c_n_instr { n_instr inside {[n_instr_min : n_instr_max]}; }
    
    top_tb_instr_gen gen;

    function new(string name = "top_tb_seq_random_tb");
        super.new(name);
    endfunction

    virtual function void build_program();
        
        if(!randomize()) `uvm_error("SEQ/RAND","Program length randomization failed")

        `uvm_info("SEQ/PROGRAM",$sformatf("Generating %0d random instructions", n_instr), UVM_LOW)

        gen = top_tb_instr_gen::type_id::create("gen");

        imem_preload = new[n_instr];

        foreach(imem_preload[i]) begin
            if(i == n_instr-1) imem_preload[i] = pkg_instruction::terminate();
            else begin
                if(!gen.randomize()) `uvm_error("SEQ/RAND", "instr_gen randomization failed")
                imem_preload[i] = gen.instr;
                `uvm_info("SEQ/INSTR",$sformatf("Generated instruction: %s",gen.convert2string()),UVM_HIGH)
            end
        end

        dmem_preload = new[config_pkg::DMEM_NUM_WORDS];
        foreach(dmem_preload[i]) dmem_preload[i] = random_vector();

        sc_prf_preload = new[config_pkg::ARCH_REG_DEPTH];
        foreach(sc_prf_preload[i]) sc_prf_preload[i] = '0;

        vc_prf_preload = new[config_pkg::ARCH_REG_DEPTH];  
        foreach(vc_prf_preload[i]) vc_prf_preload[i] = '0;

    endfunction 


endclass : top_tb_seq_random_tb