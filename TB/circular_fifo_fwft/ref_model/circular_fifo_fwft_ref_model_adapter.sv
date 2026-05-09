import lib_fifo_fwft_1push_tb_config_pkg::*;
import lib_fifo_fwft_1push_dpi_pkg::*;

class lib_fifo_fwft_1push_ref_model_adapter;

    function void create_model();
        lib_fifo_fwft_1push_model_create(BUFFER_SIZE);
    endfunction
    
    function void run_ref_model(
        input T push_dataT,
        input bit push,
        input bit pop,
        output T data_outT,
        output bit full,
        output bit empty
    );
        int num_words = ($bits(T) + 31)/32;

        bit[159:0] push_data = '0;
		bit[159:0] data_out = '0;

        push_data[$bits(T)-1:0] = push_dataT;

        lib_fifo_fwft_1push_model_run(push_data, data_out, push, pop, full, empty, num_words);

		data_outT = data_out[$bits(T)-1:0];
    
    endfunction

endclass