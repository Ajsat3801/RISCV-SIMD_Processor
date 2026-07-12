interface top_tb_if_dmem_sample (input logic clk_i);

    function automatic signal_pkg::vector_data_t get_dmem_row(
        signal_pkg::dmem_address_t address
    );

        get_dmem_row[0] = dut.u_dmem.u_dmem0.mem[address[config_pkg::DMEM_ADDR_SIZE-1:2]][31:0];
        get_dmem_row[1] = dut.u_dmem.u_dmem1.mem[address[config_pkg::DMEM_ADDR_SIZE-1:2]][31:0];
        get_dmem_row[2] = dut.u_dmem.u_dmem2.mem[address[config_pkg::DMEM_ADDR_SIZE-1:2]][31:0];
        get_dmem_row[3] = dut.u_dmem.u_dmem3.mem[address[config_pkg::DMEM_ADDR_SIZE-1:2]][31:0];

    endfunction

    function automatic void dump_dmem(
        output signal_pkg::data_t arr[config_pkg::DMEM_SIZE]
    );
        for(int i=0; i<config_pkg::DMEM_SIZE; i+=4) begin
            signal_pkg::vector_data_t row = get_dmem_row(i);
            arr[i] = row[0];
            arr[i+1] = row[1];
            arr[i+2] = row[2];
            arr[i+3] = row[3];
        end
    endfunction

endinterface