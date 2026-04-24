module sc_multiplier(
    input logic clk_i,
    input logic reset_ni,
    input logic flush_i,

    input instr_pkg::data_t multiplicand_i,
    input instr_pkg::data_t multiplier_i,
    input logic valid_i,
    
    output logic[63:0] result_o,
    output logic valid_o
);
    /*
    Radix-4 booth multiplier
    child module of sc_muldiv
    
    Partial sums 33 bits to accomodate shift lefts
    multiplier 33 bits, multiplier[0] -> Q(-1)
    Note: Multiplicand = MININT is an illegal case, and inputs will be discarded
    TODO: incorporate signed and unsigned cases for multiplicand and multiplier
    */
    typedef enum logic[4:0] {ITER0, ITER1, ITER2, ITER3, ITER4, ITER5, ITER6, ITER7, SETUP } state_e;
    logic[31:0] multiplicand, multiplicand_2s_complement;
    logic[63:0] result;
    logic[32:0] partial_sum1, partial_sum2;
    logic[32:0] multiplier, multiplier_next;
    state_e state;
    logic valid_input;

    always_comb begin

        valid_input = valid_i && multiplicand_i != 32'h80000000;

        multiplicand_2s_complement = ~multiplicand + 1'b1;

        // calculating partial_sum1
        unique case ({multiplier[2], multiplier[1], multiplier[0]}) 
            3'b000:  partial_sum1 = '0;
            3'b001:  partial_sum1 = {multiplicand[31], multiplicand};
            3'b010:  partial_sum1 = {multiplicand[31], multiplicand};
            3'b011:  partial_sum1 = {multiplicand, 1'b0};
            3'b100:  partial_sum1 = {multiplicand_2s_complement, 1'b0};
            3'b101:  partial_sum1 = {multiplicand_2s_complement[31], multiplicand_2s_complement};
            3'b110:  partial_sum1 = {multiplicand_2s_complement[31], multiplicand_2s_complement};
            3'b111:  partial_sum1 = '0;
            default: partial_sum1 = '0;
        endcase

        unique case ({multiplier[18], multiplier[17], multiplier[16]}) 
            3'b000:  partial_sum2 = '0;
            3'b001:  partial_sum2 = {multiplicand[31], multiplicand};
            3'b010:  partial_sum2 = {multiplicand[31], multiplicand};
            3'b011:  partial_sum2 = {multiplicand, 1'b0};
            3'b100:  partial_sum2 = {multiplicand_2s_complement, 1'b0};
            3'b101:  partial_sum2 = {multiplicand_2s_complement[31], multiplicand_2s_complement};
            3'b110:  partial_sum2 = {multiplicand_2s_complement[31], multiplicand_2s_complement};
            3'b111:  partial_sum2 = '0;
            default: partial_sum2 = '0;
        endcase

        multiplier_next = {multiplier[32], multiplier[32], multiplier[32:2]};
        result_o = result;


    end

    always_ff @(posedge clk_i) begin
        if(!reset_ni || flush_i) begin
            result  <= '0;
            valid_o <= 1'b0;
            multiplicand <= '0;
            multiplier   <= '0;
            state <= SETUP;
        end
        else begin
            unique case (state)
                ITER0 : begin
                    result <=   result + 
                                {{31{partial_sum1[32]}}, partial_sum1} +
                                {{15{partial_sum2[32]}}, partial_sum2, 16'b0000000000000000};
                    valid_o <= 1'b0;
                    multiplier <= multiplier_next;
                    state  <= ITER1;
                end
                ITER1 : begin
                    result <=   result + 
                                {{29{partial_sum1[32]}}, partial_sum1, 2'b00} +
                                {{13{partial_sum2[32]}}, partial_sum2, 18'b000000000000000000};
                    valid_o <= 1'b0;
                    multiplier <= multiplier_next;
                    state  <= ITER2;
                end
                ITER2 : begin
                    result <=   result + 
                                {{27{partial_sum1[32]}}, partial_sum1, 4'b0000} +
                                {{11{partial_sum2[32]}}, partial_sum2, 20'b00000000000000000000};
                    valid_o <= 1'b0;
                    multiplier <= multiplier_next;
                    state  <= ITER3;
                end
                ITER3 : begin
                    result <=   result + 
                                {{25{partial_sum1[32]}}, partial_sum1, 6'b000000} +
                                {{9{partial_sum2[32]}} , partial_sum2, 22'b0000000000000000000000};
                    valid_o <= 1'b0;
                    multiplier <= multiplier_next;
                    state  <= ITER4;
                end
                ITER4 : begin
                    result <=   result + 
                                {{23{partial_sum1[32]}}, partial_sum1, 8'b00000000} +
                                {{7{partial_sum2[32]}} , partial_sum2, 24'b000000000000000000000000};
                    valid_o <= 1'b0;
                    multiplier <= multiplier_next;
                    state  <= ITER5;
                end
                ITER5 : begin
                    result <=   result + 
                                {{21{partial_sum1[32]}}, partial_sum1, 10'b0000000000} +
                                {{5{partial_sum2[32]}} , partial_sum2, 26'b00000000000000000000000000};
                    valid_o <= 1'b0;
                    multiplier <= multiplier_next;
                    state  <= ITER6;
                end
                ITER6 : begin
                    result <=   result + 
                                {{19{partial_sum1[32]}}, partial_sum1, 12'b000000000000} +
                                {{3{partial_sum2[32]}} , partial_sum2, 28'b0000000000000000000000000000};
                    
                    valid_o <= 1'b0;
                    multiplier <= multiplier_next;
                    state  <= ITER7;
                end
                ITER7 : begin
                    result <=   result + 
                                {{17{partial_sum1[32]}}, partial_sum1, 14'b00000000000000} +
                                {{1{partial_sum2[32]}} , partial_sum2, 30'b000000000000000000000000000000};
                    valid_o <= 1'b1;
                    state  <= SETUP;
                end
                SETUP : begin
                    multiplicand <= (valid_input) ? multiplicand_i : '0;
                    multiplier   <= (valid_input) ? {multiplier_i, 1'b0} :'0;
                    result  <= '0;
                    valid_o <= 1'b0;
                    state <= (valid_input) ? ITER0 : SETUP;
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