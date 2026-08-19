
module lib_scalar_divider (
    input logic clk_i,
    input logic reset_ni,
    input logic flush_i,
    input logic [31:0] dividend_i,
    input logic [31:0] divisor_i,
    input logic unsigned_div,
    input logic valid_i,
    output logic[63:0] result_o,
    output logic valid_o
);

/*
 * NON RESTORING DIVIDER
 * for handling signed -> make everything unsigned -> restore sign in the end
 * 
 * Note: 32'h80000000 is an illegal input 
*/

typedef enum logic {READY, BUSY} divider_state_e;
divider_state_e state;

logic[4:0] count;

logic [63:0] result, result_next, dbg_shft, dbg_add;
logic negative_quotient, negative_rem;
logic [31:0] u_divisor, m, rem;

always_comb begin

    m = (result[62]) ? u_divisor : (~u_divisor + 1'b1);
    result_next = {(result[62:31] + m), result[30:0], 1'b0};
    dbg_shft = {result[62:0], 1'b0};
    dbg_add = {(dbg_shft[63:32] + m), dbg_shft[31:0]};
    if(!result_next[63]) result_next[0] = 1'b1;

    /*
    result = result_next if busy
    result = sign_ext(in) if accept_input and !unsigned div
    result = {0,in} if accept in_input and unsigned_div
    result = 0 if ready and no input

    */

    rem = (result_next[63]) ? (result_next[63:32] + u_divisor) : result_next[63:32];


end
always_ff @(posedge clk_i) begin
    if(!reset_ni || flush_i) begin
        result <= '0;
        count <= '1;
        negative_quotient <= 1'b0;
        negative_rem <= 1'b0;
        valid_o <= 1'b0;
        state <= READY;
        result_o <= '0;
    end
    else begin
        
        if(state == BUSY) begin
            result  <= result_next;
            valid_o <= (count == '0) ? 1'b1 : 1'b0;
            state   <= (count == '0) ? READY : BUSY;
            count   <= count - 1'b1;
        end

        else begin
            valid_o <= 1'b0;
            count <= '1;

            if(valid_i) begin
                if(!unsigned_div) begin
                    u_divisor <= (divisor_i[31]) ? ((~divisor_i) + 1'b1) : divisor_i;
                    result <= (dividend_i[31]) ? {32'b0, (~dividend_i + 1'b1)} : {32'b0, dividend_i};
                    negative_quotient <= dividend_i[31] ^ divisor_i[31];
                    negative_rem <= dividend_i[31];
                end
                else begin
                    u_divisor <= divisor_i;
                    result <= {32'b0, dividend_i};
                end
                state <= BUSY;
            end
            else begin
                result <= '0;
                state <= READY;
            end
        end

        // reminder = reminder + divisor is negative
        

        result_o[63:32] <= (negative_rem) ? (~rem + 1'b1) : rem;

        result_o[31:0]  <= (negative_quotient) ? (~result_next[31:0] + 1'b1) : result_next[31:0];
    end
end

endmodule