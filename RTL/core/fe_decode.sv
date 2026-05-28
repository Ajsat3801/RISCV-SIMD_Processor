/* ------------------------------------------------------------------------------------------------
 *                                       INSTRUCTION DECODER
 * ------------------------------------------------------------------------------------------------
 *  Function/Behavior
 *  ->  Decodes the fetched instructions into data & control signals
 *  ->  Jump/Branch destination PC and upper immediate instruction outputs are pre-calculated
 *  ->  Refer decoded_instr_t struct inside signal_pkg for detailed explanation
 *
 *  Inputs
 *  ->  clk, reset_n
 *  ->  raw 32bit instruction
 *  ->  PC of current instruction
 *  ->  input instruction valid
 *
 *  Outputs
 *  ->  decoded instruction sent to instruction queue
 *
 *  Notes:
 *  ->  output valid is inside decoded instruction struct
 *  ->  no flush requires as the module doesnt store current state of processor
 *  ->  ecall instruction is used as a terminate function. (happens at fetch, it doesnt reach here)
 *  ->  immediate propogated even if it does not exist for an instruction, all downstream modules 
        must gate immediate value with read_src2 to prevent garbage data
 *  ->  for stores, read_src2 is set to 0 so that the immediate is used downstream. src2 address
        does contain the address of the register to be stored, logic for this handled separately in
        the register module
 * ------------------------------------------------------------------------------------------------
*/

//import config_pkg::*;

module fe_decode(
    input  logic clk_i,
    input  logic reset_ni,

    input  signal_pkg::data_t fetched_instr_i,
    input  signal_pkg::pc_t fetched_pc_i,
    input  logic fetch_valid_i,
    output logic decode_ready_o,

    input  logic queue_ready_i,
    output packet_pkg::decoded_instr_t decoded_instr_o,
    output logic decoded_instr_en_o
);

    packet_pkg::decoded_instr_t input_instr, hold_instr;
    logic hold_en;
    logic [31:0] intermediate;
    logic in_to_out, hold_to_out, in_to_hold;

    
    //assign decoded_instr_en_o = in_to_out || hold_to_out; // send to queue
    assign decode_ready_o     = !hold_en || (in_to_out || hold_to_out); // send to fetch

    always_comb begin
        // logic values
        in_to_out   = fetch_valid_i && !hold_en && queue_ready_i;
        hold_to_out = hold_en && queue_ready_i;
        in_to_hold  = fetch_valid_i && ((!hold_en && !queue_ready_i) || (hold_en && queue_ready_i));

    end
    
    
    always_comb begin
        if (fetch_valid_i) begin
            
            input_instr.valid = fetch_valid_i;
            input_instr.chip_select = signal_pkg::NONE;
            input_instr.operation   = '0;

            input_instr.dest_address = fetched_instr_i[11:7];
            input_instr.src1_address = fetched_instr_i[19:15];
            input_instr.src2_address = fetched_instr_i[24:20];

            input_instr.imm    = fetched_instr_i[31:20];
            input_instr.extend = '0;
            
            input_instr.write_to_reg = 1'b1;
            input_instr.pre_calc     = 1'b0;
            input_instr.is_branch    = 1'b0;
            input_instr.read_src2    = 1'b0;
            input_instr.src1_vector  = 1'b0;
            input_instr.src2_vector  = 1'b0;

            case(fetched_instr_i[6:0]) 
                7'b0110111: begin 
                    // lui instruction
                    input_instr.src1_address = fetched_instr_i[31:27];
                    input_instr.src2_address = fetched_instr_i[26:22];
                    input_instr.imm = {fetched_instr_i[21:12], 2'b00};
                    input_instr.pre_calc = 1'b1;
                end
                7'b0010111: begin 
                    // auipc instruction
                    intermediate = {fetched_instr_i[31:12], 12'b000000000000};
                    intermediate = intermediate + fetched_pc_i;

                    input_instr.imm = {intermediate[21:12], 2'b00};
                    input_instr.src2_address = intermediate[26:22];
                    input_instr.src1_address = intermediate[31:27];

                    input_instr.pre_calc = 1'b1;
                end
                7'b0000011: begin
                    // scalar load instructions (only LW supported for now)
                    input_instr.chip_select = signal_pkg::CS_SLSU;
                    input_instr.operation   = {fetched_instr_i[5], fetched_instr_i[14:12]};
                end
                7'b0010011: begin
                    // i-type scalar ALU instructions
                    input_instr.chip_select = signal_pkg::CS_SALU;
                    input_instr.operation   = {1'b0, fetched_instr_i[14:12]};   
                end
                7'b0110011: begin 
                    // r-type scalar ALU instructions
                    input_instr.chip_select = (fetched_instr_i[25]) ? signal_pkg::CS_MULDIV : signal_pkg::CS_SALU;
                    input_instr.operation = {fetched_instr_i[30], fetched_instr_i[14:12]}; 
                    input_instr.read_src2   = 1'b1;
                end 
                7'b1100011: begin
                    // branch instructions
                    input_instr.chip_select = signal_pkg::CS_BRANCH;
                    input_instr.operation   = {1'b1, fetched_instr_i[14:12]};

                    intermediate = {{9{fetched_instr_i[31]}}, fetched_instr_i[31], fetched_instr_i[7], fetched_instr_i[30], fetched_instr_i[29:25], fetched_instr_i[11:8], 1'b0};
                    intermediate = intermediate + fetched_pc_i;

                    input_instr.extend = intermediate[9:0];
                    input_instr.imm = intermediate[21:10];
                    //input_instr.src2_address = intermediate[26:22];
                    //input_instr.src1_address = intermediate[31:27];
                    
                    input_instr.write_to_reg = 1'b0;
                    input_instr.pre_calc  = 1'b1;
                    input_instr.is_branch = 1'b1;
                end
                7'b0100011: begin 
                    // scalar store instructions (only SW supported for now)
                    input_instr.chip_select = signal_pkg::CS_SLSU;
                    input_instr.operation   = {fetched_instr_i[5],fetched_instr_i[14:12]};
                    input_instr.imm = {fetched_instr_i[31:25], fetched_instr_i[11:7]};
                    input_instr.write_to_reg = 1'b0;
                    input_instr.read_src2    = 1'b0;
                    // NOTE: src2 actually read, but we send operand b as imm in stores
                end
                7'b1101111: begin 
                    // Jump instructions (only jal supported for now)
                    intermediate = {{12{fetched_instr_i[31]}}, fetched_instr_i[19:12], fetched_instr_i[20], fetched_instr_i[30], fetched_instr_i[29:21], 1'b0};
                    intermediate = intermediate + fetched_pc_i;

                    input_instr.extend = intermediate[9:0];
                    input_instr.imm    = intermediate[21:10];
                    input_instr.src2_address = intermediate[26:22];
                    input_instr.src1_address = intermediate[31:27];

                    input_instr.pre_calc  = 1'b1;
                    input_instr.is_branch = 1'b1;
                end
                7'b1010111: begin 
                    // vector ALU instructions
                    input_instr.chip_select = signal_pkg::CS_VALU;
                    input_instr.operation   = fetched_instr_i[29:26];
                    input_instr.read_src2   = 1'b1;
                    input_instr.src1_vector = !fetched_instr_i[14];
                    input_instr.src2_vector = 1'b1;

                end
                7'b0000111: begin 
                    // vector load instructions (only vle32.v supported for now)
                    input_instr.chip_select = signal_pkg::CS_VLSU;
                    input_instr.operation   = {fetched_instr_i[5],fetched_instr_i[14:12]};
                    
                end
                7'b0100111: begin 
                    // vector store instructions (only vse32.v supported for now)
                    input_instr.chip_select  = signal_pkg::CS_VLSU;
                    input_instr.operation    = {fetched_instr_i[5],fetched_instr_i[14:12]};
                    input_instr.src2_address = fetched_instr_i[11:7];
                    input_instr.write_to_reg = 1'b0;
                    input_instr.src2_vector  = 1'b1;
                end
                default:
                    input_instr.valid = 1'b0;
            endcase
        end
        else input_instr = '0;
    end

    always_ff @(posedge clk_i) begin
        if (!reset_ni) begin
            decoded_instr_o <= '0;
            hold_instr  <= '0;
            hold_en <= 1'b0;
            decoded_instr_en_o <= 1'b0;
        end
        else begin
            /* LOGIC
             *  input -> output : fetch_valid_i && !hold_en && queue_ready_i;
             *  hold  -> output : hold_en && queue_ready_i;
             *  input -> hold   : fetch_valid_i && ((!hold_en && !queue_ready_i) || (hold_en && queue_ready_i));
             *  output valid    : !(in_to_out || hold_to_out);
             *  
             */ 

            if(hold_to_out) decoded_instr_o <= hold_instr;
            else if(in_to_out) decoded_instr_o <= input_instr;
            else decoded_instr_o <= '0;

            if(in_to_hold) begin
                hold_instr <= input_instr;
                hold_en <= 1'b1;
            end
            else if(hold_to_out) begin
                hold_en <= 1'b0;
            end

            decoded_instr_en_o <= in_to_out || hold_to_out; // send to queue
            
        end
    
    end

endmodule