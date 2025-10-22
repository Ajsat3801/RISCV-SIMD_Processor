/*
    Decode stage of the 5 stage pipeline
    ->  Decodes the fetched instructions into control signals
    ->  Generate immediate values
    ->  Read source values from the register
    ->  Handle flush from branch
    
    ->  Later
        ->  Hazard detection 
            if next instruction depends on a load still in MEM: add a stall
            else: prepare operands and forward control

*/

module decoder(){

    // inputs from fetch
    input clk,
    input logic[31:0] instruction,
    input logic[31:0] pc,
    input logic instr_valid,

    // connectivity to scalar register
    output[4:0] x_rs1,
    output[4:0] x_rs2,
    input logic[31:0] rs1_data,
    input logic[31:0] rs2_data,

    // connectivity to scalar ALU queues
    input logic salu_queue_ready
    output logic salu_queue_valid,
    output alu_desc_t salu_queue_data,

    // misc
    output logic decode_busy,                   // goes to fetch 
    output logic illegal_instr,
    output logic[31:0] pc_out
};

/*
     2 stage decode
     1) extract details from OPCODE
     2) get operands
*/

enum logic {IDLE, BUSY} state;
logic illegal = 0;
logic use_imm, decode_ready;
logic[4:0] rs1, rs2;
alu_desc_t alu_ops_desc;

always @(posedge clk) begin

    if(stage == IDLE && instr_valid) begin

        case(instruction[6:0]) 

            7'b0110011 : begin //add, sub, slt, sltu, XOR, OR, AND
                alu_ops_desc.rd <= instruction[11:7];
                rs1 <= instruction[19:15];
                rs2 <= instruction[24:20];
                alu_ops_desc.use_imm <= 0;
                case(instruction[14:12])
                    3'b000 : begin
                        if(instruction[31:25] == 7'b0000000) alu_ops_desc.operation <= ADD;
                        else if(instruction[31:25] == 7'b0110000) alu_ops_desc.operation <= SUB;
                        else illegal <= 1;
                    end
                    3'b010: alu_ops_desc.operation <= SLT;
                    3'b011: alu_ops_desc.operation <= SLTU;
                    3'b100: alu_ops_desc.operation <= XOR;
                    3'b110: alu_ops_desc.operation <= OR;
                    3'b111: alu_ops_desc.operation <= AND;
                endcase
            end

            7'b0010011 : begin //andi, ori, xori, sltiu, slti, addi 
                alu_ops_desc.rd <= instruction[11:7];
                rs1 <= instruction[19:15];
                alu_ops_desc.use_imm <= 1;
                alu_ops_desc.operand_b <= {{20{instruction[31]}}, instruction[31:20]};

                case(instruction[14:12]) 
                    3'b000 : alu_ops_desc.operation <= ADD;
                    3'b010 : alu_ops_desc.operation <= SLT;
                    3'b011 : alu_ops_desc.operation <= SLTU;
                    3'b100 : alu_ops_desc.operation <= XOR;
                    3'b110 : alu_ops_desc.operation <= OR;
                    3'b111 : alu_ops_desc.operation <= AND;
                    default : illegal <= 1;
                endcase
            end

            7'b1100011: begin //beq, bne, blt, bge
                // TO BE ADDRESSED LATER
            end

            7'b0000011: begin //lw
            end

            7'b0100011: begin //sw

            end
            7'b1101111: begin //jal
                //TO BE ADDRESSED LATER
            end
            7'b1110011: begin //halt
                //TO BE ADDRESSED LATER
            end
            default: begin
                illegal = 1;
            end

        endcase
        salu_queue_valid <= 0;
        stage <= BUSY;

    end

    else if(stage = BUSY) begin
        if(instr_valid) illegal = 1;
        else begin
            if(!use_imm) alu_ops_desc.operand_b <= rs2_data;
        end
        stage <= IDLE;
        decode_ready <= 1;
    end

end

assign illegal_instr = illegal;
assign decode_busy = state;
assign pc_out = pc;


assign x_rs1 = rs1;
assign x_rs2 = rs2;
assign salu_queue_valid = decode_ready && (!illegal)
assign salu_queue_data = alu_ops_desc;

endmodule