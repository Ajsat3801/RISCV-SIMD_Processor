/*
    Decode stage of the 5 stage pipeline
    ->  Decodes the fetched instructions into control signals
    ->  Generate immediate values
    ->  Read source values from the register
    ->  Handle flush from branch
*/

import instr_pkg::*;
import config_pkg::*;

module decoder(
    input logic clk,
    input logic reset_n,

    input logic[DATA_SIZE-1:0] raw_instr,
    input logic[DATA_SIZE-1:0] pc,
    input logic fetch_valid,

    output decoded_instr_t decoded_instr
);

    decoded_instr_t decoded_instr_d;
    logic [6:0] opcode;
    logic [31:0] intermediate;
    
    always_comb begin
        opcode = (valid) ? raw_instr[6:0] : '0;
        
        decoded_instr_d.valid = valid;
        decoded_instr_d.chip_select = '0;
        decoded_instr_d.operation = '0;

        decoded_instr_d.dest_address = raw_instr[11:7];
        decoded_instr_d.src1_address = raw_instr[19:15];
        decoded_instr_d.src2_address = raw_instr[24:20];

        decoded_instr_d.imm = raw_instr[31:20];
        decoded_instr_d.ext = '0;
        
        decoded_instr_d.write_to_reg = 1'b1;
        decoded_instr_d.pre_calc     = 1'b0;
        decoded_instr_d.is_branch    = 1'b0;
        decoded_instr_d.read_src2    = 1'b0;
        decoded_instr_d.sign         = 1'b0;

        if (decoded_instr_d.valid) begin
            unique case(opcode) 
                7'b0110111: begin // lui
                    decoded_instr_d.src1_address = raw_instr[31:27];
                    decoded_instr_d.src2_address = raw_instr[26:22];
                    decoded_instr_d.imm = {raw_instr[21:12], 2'b00};
                    decoded_instr_d.pre_calc = 1'b1;
                end
                7'b0010111: begin // auipc
                    intermediate = {raw_instr[31:12], 12'b000000000000};
                    intermediate = intermediate + pc;

                    decoded_instr_d.imm = {intermediate[21:12], 2'b00};
                    decoded_instr_d.src2_address = intermediate[26:22];
                    decoded_instr_d.src1_address = intermediate[31:27];

                    decoded_instr_d.pre_calc = 1'b1;
                end
                7'b0000011: begin // loads (only LW supported for now)
                    decoded_instr_d.chip_select = CS_SLSU;
                    decoded_instr_d.operation = {raw_instr[5], raw_instr[14:12]};
                end
                7'b0010011: begin // i-type ALU ops
                    decoded_instr_d.chip_select = CS_SALU;
                    decoded_instr_d.operation = {1'b0, raw_instr[14:12]};   
                end
                7'b0110011: begin // r-type ALU ops
                    decoded_instr_d.chip_select = (raw_instr[25]) ? CS_SMULDIV : CS_SALU;
                    decoded_instr_d.operation = {1'b0, raw_instr[14:12]};  
                    decoded_instr_d.read_src2 = 1'b1;
                    decoded_instr_d.sign = (raw_instr[31:25] == 7'b0110000);
                end 
                7'b1100011: begin // b-type ALU ops
                    decoded_instr_d.chip_select = CS_SALU;
                    decoded_instr_d.operation = {1'b1, raw_instr[14:12]};

                    intermediate = {9{raw_instr[31]}, raw_instr[31],raw_instr[7],raw_instr[30], raw_instr[29:25],raw_instr[11:8], 1'b0};
                    intermediate = intermediate + pc;

                    decoded_instr_d.ext = intermediate[9:0];
                    decoded_instr_d.imm = intermediate[21:10];
                    decoded_instr_d.src2_address = intermediate[26:22];
                    decoded_instr_d.src1_address = intermediate[31:27];
                    
                    decoded_instr_d.write_to_reg = 1'b0;
                    decoded_instr_d.pre_calc = 1'b1;
                    decoded_instr_d.is_branch = 1'b1;
                end
                7'b0100011: begin // stores
                    decoded_instr_d.chip_select = CS_SLSU;
                    decoded_instr_d.operation = {raw_instr[5],raw_instr[14:12]};
                    decoded_instr_d.imm = {raw_instr[31:25], raw_instr[11:7]};
                    decoded_instr_d.write_to_reg = 1'b0;
                    decoded_instr_d.read_src2 = 1'b1;
                end
                7'b1101111: begin // jal
                    intermediate = {12{raw_instr[31]}, raw_instr[19:12], raw_instr[20], raw_instr[30], raw_instr[30:21], 1'b0};
                    intermediate = intermediate + pc;

                    decoded_instr_d.ext = intermediate[9:0];
                    decoded_instr_d.imm = intermediate[21:10];
                    decoded_instr_d.src2_address = intermediate[26:22];
                    decoded_instr_d.src1_address = intermediate[31:27];

                    decoded_instr_d.pre_calc = 1'b1;
                    decoded_instr_d.is_branch = 1'b1;
                end
                7'b1010111: begin // vector ALU Ops
                    decoded_instr_d.chip_select = CS_VALU;
                    decoded_instr_d.operation = raw_instr[29:26];
                    decoded_instr_d.read_src2 = raw_instr[14];
                end
                7'b0000111: begin // vector load
                    decoded_instr_d.chip_select = CS_VALU;
                    decoded_instr_d.operation = {raw_instr[5],instr[14:12]};
                    decoded_instr_d.read_src2 = 1'b1;
                end
                7'b0100111: begin // vector store
                    decoded_instr_d.chip_select = CS_VLSU;
                    decoded_instr_d.operation = {raw_instr[5],raw_instr[14:12]};
                    decoded_instr_d.write_to_reg = 1'b0;
                    decoded_instr_d.read_src2 = 1'b1;
                end
            endcase
        end
    end

    always_ff @(posedge clk) begin
        if(!reset_n) begin
            decoded_instr <= '0;
        end
        else begin
            decoded_instr <= decoded_instr_d;
        end
    end

endmodule