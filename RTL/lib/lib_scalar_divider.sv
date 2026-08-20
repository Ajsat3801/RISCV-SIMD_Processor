
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

logic [64:0] result, result_next;
logic negative_quotient, negative_rem, div_by_zero;
logic [31:0] u_divisor, dividend_hold, rem;
logic [32:0] u_divisor_ext, m, rem_ext;

always_comb begin

    u_divisor_ext = {1'b0, u_divisor};

    m = (result[64]) ? u_divisor_ext : (~u_divisor_ext + 1'b1);

    result_next = {(result[63:31] + m), result[30:0], 1'b0};

    if(!result_next[64]) result_next[0] = 1'b1;

    /*
    result = result_next if busy
    result = sign_ext(in) if accept_input and !unsigned div
    result = {0,in} if accept in_input and unsigned_div
    result = 0 if ready and no input

    */

    rem_ext = (result_next[64]) ? (result_next[64:32] + u_divisor_ext) : result_next[64:32];
    rem = rem_ext[31:0];


end
always_ff @(posedge clk_i) begin
    if(!reset_ni || flush_i) begin
        result <= '0;
        count <= '1;
        negative_quotient <= 1'b0;
        negative_rem <= 1'b0;
        div_by_zero <= 1'b0;
        dividend_hold <= '0;
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
                
                div_by_zero <= (divisor_i == '0);
                dividend_hold <= dividend_i;

                if(!unsigned_div) begin
                    u_divisor <= (divisor_i[31]) ? ((~divisor_i) + 1'b1) : divisor_i;
                    result <= {33'b0, dividend_i[31] ? (~dividend_i + 1'b1) : dividend_i};
                    
                    // need to store result sign, the whole divide happens as unsigned.
                    negative_quotient <= dividend_i[31] ^ divisor_i[31];
                    negative_rem <= dividend_i[31];
                end
                else begin
                    u_divisor <= divisor_i;
                    result <= {33'b0, dividend_i};
                    negative_quotient <= 1'b0;
                    negative_rem <= 1'b0;
                end
                state <= BUSY;
            end
            else begin
                result <= '0;
                state <= READY;
            end
        end   

        result_o[63:32] <= (div_by_zero) ? dividend_hold : ((negative_rem) ? (~rem + 1'b1) : rem);

        result_o[31:0]  <= (div_by_zero) ? 32'hFFFF_FFFF : ((negative_quotient) ? (~result_next[31:0] + 1'b1) : result_next[31:0]);
    end
end

endmodule