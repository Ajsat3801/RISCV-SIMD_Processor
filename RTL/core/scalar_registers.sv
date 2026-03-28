import config_pkg::*;

module scalar_registers(
    input logic clk,
    input logic reset_n,

    // From ROB
    retirement_bus_if.Reg write_data,

    // From Instruction Queue
    input signal_pkg::queue_to_reg_signal_t read_data,

    // To Issue logic
    operand_bus_if.Registers rs_data_reg
);

logic[DATA_SIZE-1:0] reg_arr[NUMBER_REG_ADDR-1:0];
logic[DATA_SIZE-1:0] operand_a, operand_b;
logic reg_input_valid_q;

always_comb begin
    operand_a = '0;
    operand_b = '0;

    // combinational read
    if(read_data.valid) begin

        // read source1, guard for 0 address and bypass if read and write to same address
        if(read_data.src1_address == '0) operand_a = '0;
        else if(read_data.src1_address == write_data.rd && write_data.instr_valid) operand_a = write_data.data;
        else operand_a = reg_arr[read_data.src1_address];

        // send sign extended imm or read source2; same policy as read source1
        if(!read_data.read_src2) operand_b = {{4{read_data.imm[11]}},read_data.imm}; 
        else if(read_data.src2_address == '0) operand_b = '0;
        else if(read_data.src2_address == write_data.rd && write_data.instr_valid) operand_b = write_data.data;
        else operand_b = reg_arr[read_data.src2_address];

    end
    
end

always_ff @(posedge clk) begin
    
    if(!reset_n) begin
        for(int i=0; i<NUMBER_REG_ADDR;i++) reg_arr[i] <= '0;
    end
    
    else begin
        // writing to the register
        if(write_data.instr_valid && write_data.rd != '0) reg_arr[write_data.rd] <= write_data.data;

        rs_data_reg.operand_a <= operand_a;
        rs_data_reg.operand_b <= operand_b;
        rs_data_reg.reg_input_valid <= read_data.valid;
    end
    
end

endmodule