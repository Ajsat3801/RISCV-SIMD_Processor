module lib_scalar_multiplier(
    input logic clk_i,
    input logic reset_ni,

    input signal_pkg::data_t multiplicand_i,
    input signal_pkg::data_t multiplier_i,
    input logic unsigned_multiplicand_i,
    input logic unsigned_multiplier_i,
    input logic valid_i,
    
    output logic[63:0] result_o,
    output logic valid_o
);
    /*
    Radix-4 booth multiplier
    child module of sc_muldiv
    
    Partial sums 34 bits to accomodate shift lefts + sign extension
    multiplier 33 bits, multiplier[0] -> Q(-1)
    Note: Multiplicand = MININT is an illegal case, and inputs will be discarded
    */
    typedef enum logic[4:0] {ITER0, ITER1, ITER2, ITER3, ITER4, ITER5, ITER6, ITER7, ITER_TOP, SETUP } state_e;
    logic unsigned_multiplicand, unsigned_multiplier, top_correction_valid;
    logic[32:0] multiplicand, multiplicand_2s_complement;
    logic[63:0] result;
    logic[33:0] partial_sum1, partial_sum2, top;
    logic sign_ext, sign_ext_neg;
    logic[33:0] multiplier, multiplier_next;
    state_e state;
    logic valid_input;

    always_comb begin

        valid_input = valid_i && multiplicand_i != 32'h80000000;

        multiplicand_2s_complement = ~multiplicand + 1'b1;
        sign_ext = multiplicand[32];
        sign_ext_neg = multiplicand_2s_complement[32];

        // calculating partial_sum1
        unique case ({multiplier[2], multiplier[1], multiplier[0]}) 
            3'b000:  partial_sum1 = '0;
            3'b001:  partial_sum1 = {sign_ext, multiplicand};
            3'b010:  partial_sum1 = {sign_ext, multiplicand};
            3'b011:  partial_sum1 = {multiplicand, 1'b0};
            3'b100:  partial_sum1 = {multiplicand_2s_complement, 1'b0};
            3'b101:  partial_sum1 = {sign_ext_neg, multiplicand_2s_complement};
            3'b110:  partial_sum1 = {sign_ext_neg, multiplicand_2s_complement};
            3'b111:  partial_sum1 = '0;
            default: partial_sum1 = '0;
        endcase

        unique case ({multiplier[18], multiplier[17], multiplier[16]}) 
            3'b000:  partial_sum2 = '0;
            3'b001:  partial_sum2 = {sign_ext, multiplicand};
            3'b010:  partial_sum2 = {sign_ext, multiplicand};
            3'b011:  partial_sum2 = {multiplicand, 1'b0};
            3'b100:  partial_sum2 = {multiplicand_2s_complement, 1'b0};
            3'b101:  partial_sum2 = {sign_ext_neg, multiplicand_2s_complement};
            3'b110:  partial_sum2 = {sign_ext_neg, multiplicand_2s_complement};
            3'b111:  partial_sum2 = '0;
            default: partial_sum2 = '0;
        endcase

        multiplier_next = (unsigned_multiplier) ? {2'b00, multiplier[33:2]} : {multiplier[33], multiplier[33], multiplier[33:2]};
        result_o = result;

    end

    always_ff @(posedge clk_i) begin
        if(!reset_ni) begin
            result  <= '0;
            valid_o <= 1'b0;
            multiplicand <= '0;
            multiplier   <= '0;
            unsigned_multiplicand <= '0;
            unsigned_multiplier <= '0;
            state <= SETUP;
        end
        else begin
            unique case (state)
                ITER0 : begin
                    result <= result + {{30{partial_sum1[33]}}, partial_sum1} + {{14{partial_sum2[33]}}, partial_sum2, 16'd0};
                    valid_o <= 1'b0;
                    multiplier <= multiplier_next;
                    state  <= ITER1;
                end
                ITER1 : begin
                    result <= result + {{28{partial_sum1[33]}}, partial_sum1, 2'd0} + {{12{partial_sum2[33]}}, partial_sum2, 18'd0};
                    valid_o <= 1'b0;
                    multiplier <= multiplier_next;
                    state  <= ITER2;
                end
                ITER2 : begin
                    result <= result + {{26{partial_sum1[33]}}, partial_sum1, 4'd0} + {{10{partial_sum2[33]}}, partial_sum2, 20'd0};
                    valid_o <= 1'b0;
                    multiplier <= multiplier_next;
                    state  <= ITER3;
                end
                ITER3 : begin
                    result <= result + {{24{partial_sum1[33]}}, partial_sum1, 6'd0} + {{8{partial_sum2[33]}} , partial_sum2, 22'd0};
                    valid_o <= 1'b0;
                    multiplier <= multiplier_next;
                    state  <= ITER4;
                end
                ITER4 : begin
                    result <= result + {{22{partial_sum1[33]}}, partial_sum1, 8'd0} + {{6{partial_sum2[33]}} , partial_sum2, 24'd0};
                    valid_o <= 1'b0;
                    multiplier <= multiplier_next;
                    state  <= ITER5;
                end
                ITER5 : begin
                    result <= result + {{20{partial_sum1[33]}}, partial_sum1, 10'd0} + {{4{partial_sum2[33]}} , partial_sum2, 26'd0};
                    valid_o <= 1'b0;
                    multiplier <= multiplier_next;
                    state  <= ITER6;
                end
                ITER6 : begin
                    result <= result + {{18{partial_sum1[33]}}, partial_sum1, 12'd0} + {{2{partial_sum2[33]}} , partial_sum2, 28'd0};
                    valid_o <= 1'b0;
                    multiplier <= multiplier_next;
                    state  <= ITER7;
                end
                ITER7 : begin
                    result <= (top_correction_valid)
                        ? result + {{16{partial_sum1[33]}}, partial_sum1, 14'd0} + {partial_sum2, 30'd0} + {multiplicand[31:0],32'd0}
                        : result + {{16{partial_sum1[33]}}, partial_sum1, 14'd0} + {partial_sum2, 30'd0};
                        valid_o <= 1'b1;
                        state  <= SETUP;
                end
                SETUP : begin
                    
                    if(valid_input) begin
                        multiplicand <= (unsigned_multiplicand_i) ? {1'b0, multiplicand_i} : {multiplicand_i[31], multiplicand_i};
                        multiplier   <= (unsigned_multiplier_i)   ? {1'b0, multiplier_i, 1'b0} : {multiplier_i[31], multiplier_i, 1'b0};
                        unsigned_multiplicand <= unsigned_multiplicand_i;
                        unsigned_multiplier   <= unsigned_multiplier_i;
                        top_correction_valid  <= unsigned_multiplier_i && multiplier_i[31];
                    end
                    else begin
                        multiplicand <= '0;
                        multiplier   <= '0;
                        unsigned_multiplicand <= 1'b0;
                        unsigned_multiplier   <= 1'b0;
                        top_correction_valid  <= 1'b0;
                    end
                    result  <= '0;
                    valid_o <= 1'b0;
                    state   <= (valid_input) ? ITER0 : SETUP;
                end
                default: begin
                    multiplicand <= '0;
                    multiplier   <= '0;
                    result  <= '0;
                    valid_o <= 1'b0;
                    state <= SETUP;
                end
            endcase
        end
    end


endmodule