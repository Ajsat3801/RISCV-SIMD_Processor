/* ------------------------------------------------------------------------------------------------
 *                                       INSTRUCTION DECODE
 * ------------------------------------------------------------------------------------------------
 *  Function/Behavior
 *  ->  Decodes raw 32-bit RISC-V instruction into control signals & data fields, packaging them
 *      into a struct for downstream consumption.
 *  ->  Pre-calculates branch & jump target PCs & encodes result directly into imm/extend/src fields
 *      of the decoded packet, setting pre_calc to signal downstream that the address is ready.
 *  ->  For LUI/AUIPC, the 20-bit upper immediate is pre-computed & packed into imm/src fields with
 *      pre_calc = 1, bypassing the ALU immediate path.
 *  ->  Implements a one-entry elastic buffer (hold register) to decouple fetch throughput from
 *      instruction-queue backpressure: an incoming instruction is held if the queue is not ready,
 *      and drained on the next cycle the queue accepts data.
 *  ->  decode_ready_o is deasserted only when the hold register is occupied AND the queue is not
 *      draining it.
 *  ->  On flush or reset, everything cleared to zero.
 *  ->  Refer packet_pkg for detailed info on decoded instruction struct.
 *
 *  Inputs
 *  ->  clk, reset_n & flush
 *  ->  fetched_instr_i — Raw 32-bit instruction word from the fetch stage.
 *  ->  fetched_pc_i — Program counter of the instruction currently being decoded.
 *  ->  fetch_valid_i — Asserted by fetch when a valid instruction is fetched.
 *  ->  queue_ready_i — Asserted by instruction queue when it can accept a new instruction.
 *
 *  Outputs
 *  ->  decoded_instr_o — Decoded instruction packet sent to the instruction queue.
 *  ->  decoded_instr_en_o — Enable/valid strobe for decoded_instr_o.
 *  ->  decode_ready_o — Back-pressure signal to the fetch stage.
 *
 *  Notes:
 *  ->  The valid bit for the output lives inside the decoded_instr_t struct.
 *  ->  ECALL is handled upstream in the fetch stage and never reaches this module.
 *  ->  Immediates are always propagated regardless of instruction type. Downstream modules must
 *      gate immediate with read_src2 == 0 to avoid using garbage data on R-type instructions.
 *  ->  For store instructions, read_src2 is explicitly forced to 0 so that the ALU uses the
 *      immediate as operand B. The actual source-2 register address is still placed in 
 *      src2_address for the register file to read separately. PRF handles this quirk.
 *  ->  Unrecognized opcodes result in input_instr.valid = 0, effectively dropping the instruction silently.
 *
 * ------------------------------------------------------------------------------------------------
 */

//import config_pkg::*;

module fe_decode(
    input  logic clk_i,
    input  logic reset_ni,
    input  logic flush_i,

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
    signal_pkg::pc_t link_pc;

    
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

                    link_pc = fetched_pc_i + 1'b1;

                    input_instr.extend = intermediate[9:0];
                    input_instr.imm    = intermediate[21:10];
                    {input_instr.src1_address, input_instr.src2_address} = {2'b00, link_pc};

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
        if (!reset_ni || flush_i) begin
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