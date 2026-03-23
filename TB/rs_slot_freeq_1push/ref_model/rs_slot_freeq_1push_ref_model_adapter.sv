import rs_slot_freeq_1push_dpi_pkg;
import rs_slot_freeq_1push_tb_config_pkg;

class rs_slot_freeq_1push_ref_model_adapter;

    private int Tsize = $bits(T);
    private int numwords = (Tsize + 31) / 32;

    function void create_model();
        rs_slot_freeq_1push_model_create(BUFFER_SIZE, numwords);
    endfunction

    function void run_model(
        input T push_dataT,
        input bit push,
        input bit pop,
        input bit reset_n,
        output T data_outT,
        output bit full,
        output bit empty,
        input int numwords
    );
        
        bit[159:0] push_data, data_out;

        push_data[Tsize-1:0] = push_dataT;

        rs_slot_freeq_1push_model_run(
            push_data, 
            data_out, 
            push, 
            pop,
            full,
            empty,
            reset_n,
            numwords
        );

        data_outT = data_out[Tsize-1:0];

    endfunction

endclass