

/*
import instr_pkg::*;
import config_pkg::*;
*/

module decoder(
    input logic clk_i,
    input logic reset_ni,

    input instr_pkg::data_t raw_instr_i,
    input instr_pkg::data_t pc_i,
    input logic fetch_valid_i,

    output instr_pkg::decoded_instr_t decoded_instr_o
);

/*  INSTRUCTION DECODER
 *  Functions/Behavior
 *  ->  Decodes the fetched instructions into data & control signals
 *  ->  Jump/Branch destination PC and *UI instruction outputs are pre-calculated
 *  ->  Refer decoded_instr_t struct inside instr_pkg for detailed explanation
 *  Inputs
 *  ->  clk, reset_n
 *  ->  raw 32bit instruction
 *  ->  PC of current instruction
 *  ->  input instruction valid
 *  Outputs
 *  ->  decoded instruction sent to instruction queue
 *  Notes:
 *  ->  output valid is inside decoded instruction struct
 *  ->  no flush requires as the module doesnt store current state of processor
*/

    instr_pkg::decoded_instr_t decoded_instr_d;
    logic [6:0]  opcode;
    logic [31:0] intermediate;
    
    always_comb begin
        opcode = (fetch_valid_i) ? raw_instr_i[6:0] : '0;
        
        decoded_instr_d.valid = fetch_valid_i;
        decoded_instr_d.chip_select = NONE;
        decoded_instr_d.operation   = '0;

        decoded_instr_d.dest_address = raw_instr_i[11:7];
        decoded_instr_d.src1_address = raw_instr_i[19:15];
        decoded_instr_d.src2_address = raw_instr_i[24:20];

        decoded_instr_d.imm    = raw_instr_i[31:20];
        decoded_instr_d.extend = '0;
        
        decoded_instr_d.write_to_reg = 1'b1;
        decoded_instr_d.pre_calc     = 1'b0;
        decoded_instr_d.is_branch    = 1'b0;
        decoded_instr_d.read_src2    = 1'b0;
        decoded_instr_d.src1_vector  = 1'b0;
        decoded_instr_d.src2_vector  = 1'b0;
        decoded_instr_d.sign         = 1'b0;

        case(opcode) 
            7'b0110111: begin 
                // lui instruction
                decoded_instr_d.src1_address = raw_instr_i[31:27];
                decoded_instr_d.src2_address = raw_instr_i[26:22];
                decoded_instr_d.imm = {raw_instr_i[21:12], 2'b00};
                decoded_instr_d.pre_calc = 1'b1;
            end
            7'b0010111: begin 
                // auipc instruction
                intermediate = {raw_instr_i[31:12], 12'b000000000000};
                intermediate = intermediate + pc_i;

                decoded_instr_d.imm = {intermediate[21:12], 2'b00};
                decoded_instr_d.src2_address = intermediate[26:22];
                decoded_instr_d.src1_address = intermediate[31:27];

                decoded_instr_d.pre_calc = 1'b1;
            end
            7'b0000011: begin
                // scalar load instructions (only LW supported for now)
                decoded_instr_d.chip_select = CS_SLSU;
                decoded_instr_d.operation   = {raw_instr_i[5], raw_instr_i[14:12]};
            end
            7'b0010011: begin
                // i-type scalar ALU instructions
                decoded_instr_d.chip_select = CS_SALU;
                decoded_instr_d.operation   = {1'b0, raw_instr_i[14:12]};   
            end
            7'b0110011: begin 
                // r-type scalar ALU instructions
                decoded_instr_d.chip_select = (raw_instr_i[25]) ? CS_SMULDIV : CS_SALU;
                decoded_instr_d.operation   = {1'b0, raw_instr_i[14:12]};  
                decoded_instr_d.read_src2   = 1'b1;
                decoded_instr_d.sign = (raw_instr_i[31:25] == 7'b0110000);
            end 
            7'b1100011: begin
                // branch instructions
                decoded_instr_d.chip_select = CS_SALU;
                decoded_instr_d.operation   = {1'b1, raw_instr_i[14:12]};

                intermediate = {{9{raw_instr_i[31]}}, raw_instr_i[31], raw_instr_i[7], raw_instr_i[30], raw_instr_i[29:25], raw_instr_i[11:8], 1'b0};
                intermediate = intermediate + pc_i;

                decoded_instr_d.extend = intermediate[9:0];
                decoded_instr_d.imm = intermediate[21:10];
                decoded_instr_d.src2_address = intermediate[26:22];
                decoded_instr_d.src1_address = intermediate[31:27];
                
                decoded_instr_d.write_to_reg = 1'b0;
                decoded_instr_d.pre_calc  = 1'b1;
                decoded_instr_d.is_branch = 1'b1;
            end
            7'b0100011: begin 
                // scalar store instructions (only SW supported for now)
                decoded_instr_d.chip_select = CS_SLSU;
                decoded_instr_d.operation   = {raw_instr_i[5],raw_instr_i[14:12]};
                decoded_instr_d.imm = {raw_instr_i[31:25], raw_instr_i[11:7]};
                decoded_instr_d.write_to_reg = 1'b0;
                decoded_instr_d.read_src2    = 1'b1;
            end
            7'b1101111: begin 
                // Jump instructions (only jal supported for now)
                intermediate = {{12{raw_instr_i[31]}}, raw_instr_i[19:12], raw_instr_i[20], raw_instr_i[30], raw_instr_i[30:21], 1'b0};
                intermediate = intermediate + pc_i;

                decoded_instr_d.extend = intermediate[9:0];
                decoded_instr_d.imm    = intermediate[21:10];
                decoded_instr_d.src2_address = intermediate[26:22];
                decoded_instr_d.src1_address = intermediate[31:27];

                decoded_instr_d.pre_calc  = 1'b1;
                decoded_instr_d.is_branch = 1'b1;
            end
            7'b1010111: begin 
                // vector ALU instructions
                decoded_instr_d.chip_select = CS_VALU;
                decoded_instr_d.operation   = raw_instr_i[29:26];
                decoded_instr_d.read_src2   = 1'b1;
                decoded_instr_d.src1_vector = !raw_instr_i[14];
                decoded_instr_d.src2_vector = 1'b1;

            end
            7'b0000111: begin 
                // vector load instructions (only vle32.v supported for now)
                decoded_instr_d.chip_select = CS_VALU;
                decoded_instr_d.operation   = {raw_instr_i[5],raw_instr_i[14:12]};
                
            end
            7'b0100111: begin 
                // vector store instructions (only vse32.v supported for now)
                decoded_instr_d.chip_select  = CS_VLSU;
                decoded_instr_d.operation    = {raw_instr_i[5],raw_instr_i[14:12]};
                decoded_instr_d.src2_address = raw_instr_i[11:7];
                decoded_instr_d.write_to_reg = 1'b0;
                decoded_instr_d.src2_vector  = 1'b1;
            end
            // not included default becase no change to initial values
        endcase
    end

    always_ff @(posedge clk_i) begin
        if (!reset_ni) begin
            decoded_instr_o <= '0;
        end
        else begin
            if (fetch_valid_i) begin
                decoded_instr_o <= decoded_instr_d;
            end
            else begin
                decoded_instr_o <= '0;
            end
        end
    end

endmodule