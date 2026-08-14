// top tb preload interface

interface top_tb_if_preload (input logic clk_i, input logic reset_ni);

    logic compute;

    logic imem_preload_en;
    packet_pkg::imem_request_t preload_imem_request;

    logic dmem_preload_en;
    packet_pkg::dmem_request_t preload_dmem_request;

    logic sc_prf_preload_en;
    signal_pkg::data_t sc_prf_preload_data;
    signal_pkg::prf_tag_t sc_prf_preload_addr;

    logic vc_prf_preload_en;
    signal_pkg::vector_data_t vc_prf_preload_data;
    signal_pkg::prf_tag_t vc_prf_preload_addr;

    task automatic drive_preload(
        input logic imem_en = 1'b0,
        input signal_pkg::imem_address_t imem_address = '0,
        input signal_pkg::data_t imem_data = '0,

        input logic dmem_en = 1'b0,
        input logic [config_pkg::DMEM_NUM_BANKS-1:0] dmem_write_enable = '0,
        input signal_pkg::dmem_word_address_t dmem_address = '0,
        input signal_pkg::vector_data_t dmem_data = '0,

        input logic sc_prf_en = 1'b0,
        input signal_pkg::data_t sc_prf_data = '0,
        input signal_pkg::prf_tag_t sc_prf_address = '0,

        input logic vc_prf_en = 1'b0,
        input signal_pkg::vector_data_t vc_prf_data = '0,
        input signal_pkg::prf_tag_t vc_prf_address = '0

    );
        /*  Task to preload data into DUT
         *  calling this function without args result in sending the default values which results
         *  in no op state
         */
        @(posedge clk_i);
        
        imem_preload_en <= imem_en;

        preload_imem_request.read_enable <= 1'b1;
        preload_imem_request.write_enable <= imem_en;
        preload_imem_request.address <= imem_address;
        preload_imem_request.data <= imem_data;
        
        dmem_preload_en  <= dmem_en;
        preload_dmem_request.write_enable <= dmem_write_enable;
        preload_dmem_request.address <= dmem_address;
        preload_dmem_request.data <= dmem_data;
        
        sc_prf_preload_en <= sc_prf_en;
        sc_prf_preload_data <= sc_prf_data;
        sc_prf_preload_addr <= sc_prf_address;
        
        vc_prf_preload_en <= vc_prf_en;
        vc_prf_preload_data <= vc_prf_data;
        vc_prf_preload_addr <= vc_prf_address;
        
    endtask : drive_preload

    task automatic drive_compute(bit start);
        /* Task that sends signal to DUT to start computation
         * Run once and compute set to 1, doesnt reset in every cycle
         */
        drive_preload();
        compute <= start;

    endtask  : drive_compute
    
    task automatic idle();

        /*  default state when there is no preload
         *  Note: same as calling drive with no args, wrapper for readablity
         */

        drive_preload();
    endtask : idle

    task automatic reset();
        /*  Also works as initial state
         */

        compute = 1'b0;

        imem_preload_en = 1'b0;
        preload_imem_request = '0;

        dmem_preload_en = 1'b0;
        preload_dmem_request = '0;

        sc_prf_preload_en = 1'b0;
        sc_prf_preload_data = '0;
        sc_prf_preload_addr = '0;

        vc_prf_preload_en = 1'b0;
        vc_prf_preload_data = '0;
        vc_prf_preload_addr = '0;

        wait (reset_ni === 1'b1);
        @(posedge clk_i);

    endtask : reset
    
endinterface : top_tb_if_preload