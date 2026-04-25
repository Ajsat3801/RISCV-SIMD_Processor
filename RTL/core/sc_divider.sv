
module sc_divider (
    input logic clk_i,
    input logic reset_ni,
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

logic [63:0] result, result_next;
logic negative_output;
logic [31:0] u_divisor, m;

always_comb begin

    m = (result[62]) ? u_divisor : (~u_divisor + 1'b1);
    result_next = {(result[62:31] + m), result[30:0], 1'b0};
    if(!result_next[63]) result_next[0] = 1'b1;

    result_o = result;


end
always_ff @(posedge clk_i) begin
    if(!reset_ni) begin
        result <= '0;
        count <= '1;
        negative_output <= 1'b0;
        valid_o <= 1'b0;
    end
    else begin
        // begins operation
        if(valid_i && state == READY) begin
            if(!unsigned_div) begin
                u_divisor <= (divisor_i[31]) ? ((~divisor_i) + 1'b1) : divisor_i;
                result <= (dividend_i[31]) ? {32'b0, (~dividend_i + 1'b1)} : {32'b0, dividend_i};
                negative_output <= dividend_i[31] ^ divisor_i[31];
            end
            else begin
                u_divisor <= divisor_i;
                result <= {32'b0, dividend_i};
            end
            count <= '1;
            state <= BUSY;
        end

        if(state == BUSY) begin
            if(count == '0) begin
                state <= READY;
                valid_o <= 1'b1;
                count <= '1;
            end
            else begin
                valid_o <= 1'b0;
                count <= count - 1'b1;
            end
        end
        else begin
            valid_o <= 1'b0;
        end
    end
end

endmodule