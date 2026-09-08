
class top_tb_seq_random_tb extends top_tb_seq_program_base;

    `uvm_object_utils(top_tb_seq_random_tb)

    rand int unsigned n_instr;

    int unsigned n_instr_min = 16;
    int unsigned n_instr_max = config_pkg::IMEM_DEPTH;

    constraint c_n_instr { n_instr inside {[n_instr_min : n_instr_max]}; }
    
    top_tb_instr_gen gen;

    function new(string name = "top_tb_seq_random_tb");
        super.new(name);
    endfunction

    virtual function void build_program();
        
        if(!randomize()) `uvm_error("SEQ/RAND","Program length randomization failed")

        `uvm_info("SEQ/PROGRAM",$sformatf("Generating %0d random instructions", n_instr), UVM_LOW)

        gen = top_tb_instr_gen::type_id::create("gen");

        gen.set_program_length(n_instr);

        dmem_preload = new[config_pkg::DMEM_BANK_DEPTH];
        foreach(dmem_preload[i]) dmem_preload[i] = random_vector();

        sc_prf_preload = new[config_pkg::ARCH_REG_DEPTH];
        foreach(sc_prf_preload[i]) sc_prf_preload[i] = '0;

        // fixed values to get edge cases
        sc_prf_preload[0] = 0;
        sc_prf_preload[1] = 32'd1;
        sc_prf_preload[2] = 32'h8000_0000; // int min
        sc_prf_preload[3] = 32'h7fff_ffff; // int max
        sc_prf_preload[4] = random_word();         // random small number

        gen.set_random_small_no(sc_prf_preload[4]);

        vc_prf_preload = new[config_pkg::ARCH_REG_DEPTH];  
        foreach(vc_prf_preload[i]) vc_prf_preload[i] = '0;

        imem_preload = new[n_instr];

        foreach(imem_preload[i]) begin

            if(i == n_instr-1) imem_preload[i] = pkg_instruction_encoding::terminate();
            
            else begin
                
                gen.set_current_pc(i);

                if(!gen.randomize()) `uvm_error("SEQ/RAND", "instr_gen randomization failed")
                imem_preload[i] = gen.instr;

                `uvm_info("SEQ/INSTR",$sformatf("Generated instruction: %s",gen.convert2string()),UVM_HIGH)
            end

        end

        

    endfunction 


endclass : top_tb_seq_random_tb