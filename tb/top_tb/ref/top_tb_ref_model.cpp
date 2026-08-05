
#include <vector>
#include <cstdint> // Required for uint32_t / int32_t / INT32_MIN
#include <svdpi.h>

struct decoded_instr_t {
    uint32_t rd, rs1, rs2;
    uint32_t opcode, funct3, funct7;
    int32_t imm;
    bool vv; // differentiates between .vv and .vx instructions,
};

class top_funct_sim {

    /*  -------------------------------------------------------------------------------------------
     *                                   Functional Simulation model
     *  -------------------------------------------------------------------------------------------
     *
     *  ->  Class that is the golden reference for the end result of the run
     *  ->  Preload function called everytime monitor gets a preload transaction. The model is 
     *      run and the results are dumped only after the DUT finishes execution.
     *  ->  Does not model PRF or RAT or any out-of-order optimizations. This is purely functional 
     *      and instructions run in order with no cycle counts or performance models
     *  ->  2 stages, decode and execute. Execute involves reading operands, executing and
     *      writeback
     *  ->  Decoded_instr_t struct does not have any data in it, its just addresses and flags. 
     *  ->  vlen, imem_num_words, dmem_num_words and dmem_size are const config parameters
     *  ->  IMP NOTE: DMEM and Vector reg inputs and outputs is flattened, its not 2D data
     *  -------------------------------------------------------------------------------------------
    */

    private:

        // config variables set during construction    
        const int vlen; // lanes per vector register (VECTOR_SIZE)
        const int imem_num_words;
        const int dmem_num_words;
        const int dmem_size; // dmem_size * vlen (vlen == number of banks)

        std::vector<uint32_t> sc_registers;              // 32 scalar regs
        std::vector<std::vector<uint32_t>> vc_registers; // 32 vec regs x 4 lanes

        std::vector<uint32_t> imem;
        std::vector<uint32_t> dmem;

        uint32_t pc;

        
        decoded_instr_t decode(uint32_t raw_instr) {

            // populating struct fields
            decoded_instr_t in;
            in.opcode = raw_instr & 0x7F;
            in.rd     = (raw_instr >> 7)  & 0x1F;
            in.funct3 = (raw_instr >> 12) & 0x7;
            in.rs1    = (raw_instr >> 15) & 0x1F; // vs1/rs1 for vector
            in.rs2    = (raw_instr >> 20) & 0x1F; // vs2      for vector
            in.funct7 = (raw_instr >> 25) & 0x7F;
            in.vv     = false;

            // ----- immediate, selected by instruction format -----
            switch (in.opcode) {
                case 0b0010011: // I type
                case 0b0000011: // lw
                case 0b0000111: // vle
                    // sign-extend inst[31:20]
                    in.imm = ((int32_t)raw_instr) >> 20;
                    break;

                case 0b0100011: // sw
                case 0b0100111: // vse
                    in.imm = (((int32_t)raw_instr >> 25) << 5)   // imm[11:5] (sign-ext)
                           | ((raw_instr >> 7) & 0x1F);          // imm[4:0]
                    break;

                case 0b1100011: // branches
                    in.imm = ((int32_t)(raw_instr & 0x80000000) >> 19) // imm[12] + sign
                           | ((raw_instr & 0x7E000000) >> 20)          // imm[10:5]
                           | ((raw_instr & 0x00000F00) >> 7)           // imm[4:1]
                           | ((raw_instr & 0x00000080) << 4);          // imm[11]
                    break;

                case 0b0110111: // lui
                case 0b0010111: // auipc
                    in.imm = raw_instr & 0xFFFFF000;
                    break;

                case 0b1101111: // jal
                    in.imm = ((int32_t)(raw_instr & 0x80000000) >> 11) // imm[20] + sign
                           | (raw_instr & 0x000FF000)                  // imm[19:12]
                           | ((raw_instr & 0x00100000) >> 9)           // imm[11]
                           | ((raw_instr & 0x7FE00000) >> 20);         // imm[10:1]
                    break;

                default: // R type or OPIVV/OPIVX or unsupported instruction
                    in.imm = 0;
                    break;
            }

            // Vector ALU op: funct3 000 -> OPIVV, 100 -> OPIVX).
            // funct7 LSB is vm (mask). Hardwiring it to 0 to as masking not supported in core.
            if (in.opcode == 0b1010111) {
                in.vv     = (in.funct3 == 0b000);
                in.funct7 = in.funct7 & 0b1111110;
            }

            return in;
        };

        void vec_alu(const decoded_instr_t& in, int op, bool rsub = false) {
            
            // Apply one vector ALU op across all lanes.
            //   A = vc[rs2][lane];  B = .vv ? vc[rs1][lane] : sc[rs1]
            //   rsub == true  -> result = B - A   (vrsub only)

            for (int l = 0; l < vlen; l++) {
                uint32_t A = vc_registers[in.rs2][l];
                uint32_t B = in.vv ? vc_registers[in.rs1][l] : sc_registers[in.rs1];
                uint32_t r = 0;
                switch (op) {
                    case 0: r = rsub ? (B - A) : (A + B); break; // add / rsub
                    case 1: r = A - B; break; // sub
                    case 2: r = A & B; break; // and
                    case 3: r = A | B; break; // or
                    case 4: r = A ^ B; break; // xor
                }
                vc_registers[in.rd][l] = r;
            }
        }

        void execute (decoded_instr_t in) {
            uint32_t next_pc = pc + 1; // PC += 1

            uint32_t a = sc_registers[in.rs1];
            uint32_t b = sc_registers[in.rs2];

            switch ((in.opcode)){
            case 0b0110111: sc_registers[in.rd] = in.imm; break;      //lui
            case 0b0010111: sc_registers[in.rd] = in.imm + pc; break; //auipc (word-pc)

            case 0b0010011: // I Type ALU Operations
                switch(in.funct3) {
                    case 0b000: sc_registers[in.rd] = a + in.imm; break; // addi
                    case 0b001: sc_registers[in.rd] = a << (in.imm & 0x1F); break; // slli
                    case 0b010: sc_registers[in.rd] = ((int32_t)a < in.imm) ? 1 : 0; break; // slti
                    case 0b011: sc_registers[in.rd] = (a < (uint32_t)in.imm) ? 1 : 0; break; // sltiu
                    case 0b100: sc_registers[in.rd] = a ^ in.imm; break; // xori
                    case 0b101: if (in.funct7 == 0) sc_registers[in.rd] = a >> (in.imm & 0x1F); break; // srli
                    case 0b110: sc_registers[in.rd] = a | in.imm; break; // ori
                    case 0b111: sc_registers[in.rd] = a & in.imm; break; // andi
                    default: break;
                }
                break;

            case 0b0110011: // R-type: RV32I + RV32M
                switch(in.funct7) {
                    case 0b0100000: if(in.funct3 == 0b000) sc_registers[in.rd] = a - b; break; // sub
                    case 0b0000000:
                        switch(in.funct3) { // R type ALU ops
                            case 0b000: sc_registers[in.rd] = a + b; break; // add
                            case 0b001: sc_registers[in.rd] = a << (b & 0x1F); break; // sll
                            case 0b010: sc_registers[in.rd] = ((int32_t)a < (int32_t)b) ? 1 : 0; break; // slt
                            case 0b011: sc_registers[in.rd] = (a < b) ? 1 : 0; break; // sltu
                            case 0b100: sc_registers[in.rd] = a ^ b; break; // xor
                            case 0b101: sc_registers[in.rd] = a >> (b & 0x1F); break; // srl
                            case 0b110: sc_registers[in.rd] = a | b; break; // or
                            case 0b111: sc_registers[in.rd] = a & b; break; // and
                            default: break;
                        }
                        break;
                    case 0b0000001:
                        switch(in.funct3) { // R type MULDIV ops
                            int32_t sa = (int32_t)a;
                            int32_t sb = (int32_t)b;  
                            
                            case 0b000: sc_registers[in.rd] = a * b; break;  // mul (low32)
                            case 0b001: sc_registers[in.rd] = (uint32_t)(((int64_t)sa * (int64_t)sb) >> 32); break; // mulh
                            case 0b010: sc_registers[in.rd] = (uint32_t)(((int64_t)sa * (int64_t)(uint32_t)b) >> 32); break; // mulhsu
                            case 0b011: sc_registers[in.rd] = (uint32_t)(((uint64_t)a * (uint64_t)b) >> 32); break; // mulhu
                            case 0b100:  // div
                                    if (sb == 0 || (sa == INT32_MIN && sb == -1) ) sc_registers[in.rd] = 0xFFFFFFFF; // illegal cases
                                    else sc_registers[in.rd] = (uint32_t)(sa / sb);
                                    break;
                            case 0b101: sc_registers[in.rd] = (b == 0) ? 0xFFFFFFFF : (a / b); break; // divu
                            case 0b110: // rem
                                    if (sb == 0 || (sa == INT32_MIN && sb == -1)) sc_registers[in.rd] = 0;
                                    else  sc_registers[in.rd] = (uint32_t)(sa % sb);
                                    break;
                            case 0b111: sc_registers[in.rd] = (b == 0) ? a : (a % b); break; // remu
                            default: break;
                        }
                        break;
                    default: break;
                }
                break;

            case 0b1100011: // Branch
                switch(in.funct3) {
                    case 0b000: if (a == b) next_pc = pc + in.imm; break; // beq
                    case 0b001: if (a != b) next_pc = pc + in.imm; break; // bne
                    case 0b100: if ((int32_t)a < (int32_t)b) next_pc = pc + in.imm; break; // blt
                    case 0b101: if ((int32_t)a >= (int32_t)b) next_pc = pc + in.imm; break; // bge
                    case 0b110: if (a <  b) next_pc = pc + in.imm; break; // bltu
                    case 0b111: if (a >= b) next_pc = pc + in.imm; break; // bgeu
                    default: break;
                }
                break;

            case 0b0000011: // scalar loads (only lw for now; others not supported)
                switch(in.funct3) {
                    case 0b010: sc_registers[in.rd] = dmem[a + in.imm]; break; // lw
                    default: break;
                }
                break;

            case 0b0100011: // scalar stores (only sw for now; others not supported)
                switch(in.funct3) {
                    case 0b010: dmem[a + in.imm] = b; break; // sw
                    default: break;
                }
                break;

            case 0b1101111: // JAL (J-type)
                sc_registers[in.rd] = pc + 1;   // link = next word
                next_pc = pc + in.imm;          // target (word offset)
                break;

            case 0b1010111: // vector arithmetic (OP-V)
                switch (in.funct3) {
                    case 0b000: // .vv
                        switch (in.funct7){
                            case 0b0000000: vec_alu(in, 0); break; // vadd.vv
                            case 0b0000100: vec_alu(in, 1); break; // vsub.vv
                            case 0b0010010: vec_alu(in, 2); break; // vand.vv
                            case 0b0010100: vec_alu(in, 3); break; // vor.vv
                            case 0b0010110: vec_alu(in, 4); break; // vxor.vv
                            default: break;
                        }
                        break;
                    case 0b100: // .vx
                        switch (in.funct7){
                            case 0b0000000: vec_alu(in, 0); break; // vadd.vx
                            case 0b0000100: vec_alu(in, 1); break; // vsub.vx
                            case 0b0000110: vec_alu(in, 0, true); break; // vrsub.vx
                            case 0b0010010: vec_alu(in, 2); break; // vand.vx
                            case 0b0010100: vec_alu(in, 3); break; // vor.vx
                            case 0b0010110: vec_alu(in, 4); break; // vxor.vx
                            default: break;
                        }
                        break;
                    default: break;
                }
                break;

            case 0b0000111: // vector load
                if (in.funct3 == 0b110) { // vle32.v
                    for (int l = 0; l < vlen; l++) vc_registers[in.rd][l] = dmem[a + l];
                }
                break;

            case 0b0100111: // vector store
                if (in.funct3 == 0b110) { // vse32.v
                    for (int l = 0; l < vlen; l++) dmem[a + l] = vc_registers[in.rd][l];
                }
                break;

            default:
                break; // spec: unrecognized opcodes silently dropped (valid=0)
            }

            sc_registers[0] = 0; // x0 is hardwired zero
            pc = next_pc;
        }

    public:
        // imem_words : size of instruction memory (in words)
        top_funct_sim(int imem_num_words, int dmem_num_words, int vlen)
            : vlen(vlen),
              imem_num_words(imem_num_words),
              dmem_num_words(dmem_num_words),
              dmem_size(dmem_num_words*vlen),
              sc_registers(32, 0),
              vc_registers(32, std::vector<uint32_t>(vlen, 0)),
              imem(imem_num_words, 0),
              dmem(dmem_num_words*vlen, 0),
              pc(0) {}

        
        // run whole program in order
        void compute(uint32_t max_steps = 100000) {
            
            for (uint32_t i = 0; i < max_steps; i++) {
                if (pc >= imem.size()) break;

                uint32_t raw = imem[pc];
                if ((raw & 0x7F) == 0b1110011) break; // ECALL = program terminator

                execute(decode(raw));
            }
        }

        // getters and setters
        uint32_t get_sc_reg(uint32_t idx) const { return sc_registers[idx]; }
        uint32_t get_vc_reg(int idx, int lane) const { return vc_registers[idx][lane]; }
        uint32_t get_dmem(uint32_t idx) const { return dmem[idx]; }
        uint32_t get_vlen() const { return vlen; }
        uint32_t get_dmem_size() const { return dmem_size; }

        void set_pc(uint32_t p) { pc = p;}

        void set_imem(int idx, uint32_t val) { imem[idx] = val;}
        void set_dmem(int idx, std::vector<uint32_t> val) { 
            for(int i=0; i<vlen; i++) {
                dmem[(idx*vlen)+i] = val[i];
            }
        }

        void set_sc_reg(int idx, uint32_t val) { sc_registers[idx] = (idx == 0) ? 0 : val; }
        void set_vc_reg(int idx, int lane, uint32_t val) { vc_registers[idx][lane] = val;}

        void set_vc_reg(int idx, std::vector<uint32_t> val) { 
            for(int i=0; i<vlen; i++) {
                vc_registers[idx][i] = val[i];
            }
        }


        // functions to return final architectural state (read by scoreboard via DPI)

        std::vector<uint32_t> dump_sc_regs(){
            std::vector<uint32_t> sc_regs(32,0);
            for(int i=0; i<32; i++) sc_regs[i] = get_sc_reg(i);
            return sc_regs;
        }

        std::vector<uint32_t> dump_vc_regs(){
            std::vector<uint32_t> vc_regs(32*vlen,0);
            for(int i=0; i<32; i++) {
                for(int j=0; j<vlen; j++){
                    vc_regs[(i*vlen)+j] = get_vc_reg(i,j);
                }
            }
            return vc_regs;
        }

        std::vector<uint32_t> dump_dmem(){
            std::vector<uint32_t> dmem_dump(dmem_size, 0);
            for(int i=0; i<dmem_size; i++) dmem_dump[i] = get_dmem(i);
            return dmem_dump;
        }

};

// initialize reference model

top_funct_sim* model;

extern "C" void top_tb_ref_model_init(
    int imem_num_words,
    int dmem_num_words,
    int vlen
){
    model = new top_funct_sim(imem_num_words, dmem_num_words, vlen);
}

// function to preload imem, dmem and registers

extern "C" void top_tb_ref_model_preload(
    svBit imem_preload_en,
    int imem_preload_addr,
    unsigned int imem_preload_data,

    svBit dmem_preload_en,
    int dmem_preload_write_enable, // ignored because used only during operation
    int dmem_preload_addr,
    const unsigned int* dmem_preload_data, // array of unsigned ints, passed as pointer

    svBit sc_prf_preload_en,
    int sc_prf_preload_addr,
    unsigned int sc_prf_preload_data,

    svBit vc_prf_preload_en,
    int vc_prf_preload_addr,
    const unsigned int* vc_prf_preload_data // array of unsigned ints, passed as pointer
){
    
    // preloading into IMEM
    if(imem_preload_en) model->set_imem(imem_preload_addr, imem_preload_data);

    // converting 
    if(dmem_preload_en) {
        std::vector<uint32_t> val(model->get_vlen(), 0);
        for(int i=0; i<model->get_vlen(); i++) val[i] = dmem_preload_data[i];
        model->set_dmem(dmem_preload_addr, val);
    }

    if(sc_prf_preload_en) model->set_sc_reg(sc_prf_preload_addr, sc_prf_preload_data);

    if(vc_prf_preload_en) {
        std::vector<uint32_t> val(model->get_vlen(), 0);
        for(int i=0; i<model->get_vlen(); i++) val[i] = vc_prf_preload_data[i];
        model->set_vc_reg(vc_prf_preload_addr, val);
    }

}

// function to start running and return final arch states

extern "C" void top_tb_ref_model_simulate(
    unsigned int* sc_regs_final,
    unsigned int* vc_regs_final,
    unsigned int* dmem_final
){
    model->compute();
    
    std::vector<uint32_t> sc_regs_dump = model->dump_sc_regs();
    std::vector<uint32_t> vc_regs_dump = model->dump_vc_regs();
    std::vector<uint32_t> dmem_dump = model->dump_dmem();

    for(int i=0; i<32; i++) sc_regs_final[i] = sc_regs_dump[i];
    for(int i=0; i<32*model->get_vlen(); i++) vc_regs_final[i] = vc_regs_dump[i];
    for(int i=0; i<model->get_dmem_size(); i++) dmem_final[i] = dmem_dump[i];
}
