
class top_tb_seq_program_base extends top_tb_seq_base;

    `uvm_object_utils(top_tb_seq_program_base)

    signal_pkg::data_t imem_preload[];
    signal_pkg::vector_data_t dmem_preload[];
    signal_pkg::data_t sc_prf_preload[];
    signal_pkg::vector_data_t vc_prf_preload[];

    top_tb_seq_preload seq_preload;
    top_tb_seq_compute seq_compute;

    function new(string name = "top_tb_seq_program_base");
        super.new(name);
    endfunction : new

    virtual task body();

        build_program();

        if(imem_preload.size() == 0)
            `uvm_fatal("SEQ/NOPROGRAM", "build_program() produced an empty image")

        dump_program();

        seq_preload = top_tb_seq_preload::type_id::create("seq_preload");
        seq_compute = top_tb_seq_compute::type_id::create("seq_compute");

        seq_preload.imem_preload = imem_preload;
        seq_preload.dmem_preload = dmem_preload;
        seq_preload.sc_prf_preload = sc_prf_preload;
        seq_preload.vc_prf_preload = vc_prf_preload;

        seq_preload.start(m_sequencer, this);

        seq_compute.start_compute(m_sequencer, this);

        `uvm_info("SEQ", "Compute asserted, stimulus complete", UVM_LOW)

    endtask : body

    virtual function void build_program();
        `uvm_fatal("SEQ/NO_BUILD","build_program() not overwritten")

    endfunction : build_program

    virtual function void dump_program();
        
        `uvm_info("SEQ/PROGRAM", $sformatf("Program: %0d instructions", imem_preload.size()), UVM_LOW)

        foreach(imem_preload[i])
            `uvm_info("SEQ/PROGRAM", $sformatf("[%3d] %08h", i, imem_preload[i]), UVM_MEDIUM)

    endfunction : dump_program

    protected function signal_pkg::data_t random_word();

        signal_pkg::data_t w;

        if(!std::randomize(w) with {
            w dist {
                32'h0000_0000               := 5,   // zero
                32'h0000_0001               := 5,   // one
                32'hFFFF_FFFF               := 5,   // -1
                32'h8000_0000               := 5,   // INT_MIN
                32'h7FFF_FFFF               := 5,   // INT_MAX
                [32'd2 : 32'd1023]          :/ 20,  // small positives
                [32'd1024 : 32'hFFFF_FFFE]  :/ 60   // everything else
            };
        })
            `uvm_error("SEQ/RAND", "random_word() randomization failed")

        random_word = w;

    endfunction : random_word

    protected function signal_pkg::vector_data_t random_vector();

        signal_pkg::vector_data_t v;
        foreach(v[i]) begin
            v[i] = random_word();
        end

        random_vector = v;

    endfunction : random_vector

    protected function signal_pkg::data_t random_instruction();

        // Todo: complete body

    endfunction : random_instruction

    //  -------------------------------------------------------------------------------------------
    //                                               Instructions
    //  -------------------------------------------------------------------------------------------

    `include "top_tb_instruction_encoding.sv"
    `include "top_tb_instructions_alu.sv"
    `include "top_tb_instructions_br.sv"
    `include "top_tb_instructions_misc.sv"
    `include "top_tb_instructions_muldiv.sv"
    `include "top_tb_instructions_vector.sv"

endclass : top_tb_seq_program_base