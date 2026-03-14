// define separate named entry points for expected and actual data
`uvm_analysis_imp_decl(_expected)
`uvm_analysis_imp_decl(_actual)

class circular_fifo_fwft_scoreboard #(
    parameter type T = logic[31:0];
) extends uvm_scoreboard;

    `uvm_component_param_utils(circular_fifo_fwft_scoreboard #(T))

    import "DPI-C" function void circular_fifo_fwft_model_create(int id);
    import "DPI-C" function void circular_fifo_fwft_model_push(int id, T data, int numwords);
    import "DPI-C" function void circular_fifo_fwft_model_pop(int id, output T data_out, int numwords);

    uvm_analysis_imp_expected #(circular_fifo_fwft_transaction #(T), circular_fifo_fwft_scoreboard#(T)) exp_imp;
    uvm_analysis_imp_actual #(circular_fifo_fwft_transaction #(T), circular_fifo_fwft_scoreboard #(T)) act_imp;

    static int global_id_count = 0; // we are creating unique ID for each instance of queue in the model
    local int m_id;
    static int num_words = ($bits(T) + 31)/32;

    function new(string name, uvm_component parent);
        super.new(name, parent);
        m_id = global_id_count++;
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        exp_imp = new("exp_imp", this);
        act_imp = new("act_imp", this);

        circular_fifo_fwft_model_create(m_id);
    endfunction

    virtual function void write_expected(circular_fifo_fwft_transaction #(T) tr);
        if(tr.push) begin
            `uvm_info("SCB_IN",$sformatf("Pushing %h to C++ model [ID:%d]",tr.push_data,m_id), UVM_HIGH)
            circular_fifo_fwft_model_push(m_id, tr.push_data, num_words);
        end
    endfunction

    virtual function void write_actual(circular_fifo_fwft_transaction #(T) tr);
        if(tr.pop) begin
            T expected_val;
            circular_fifo_fwft_model_pop(m_id, expected_val, num_words);

            if(tr.data_out !== expected_val) begin
                `uvm_error("SCB_MISMATCH", $sformatf("[ID:%0d] Expected: %h | RTL Op: %h", m_id, expected_val, tr.data_out))
            end else begin
                `uvm_info("SCB_MATCH", $sformatf("[ID:%d] Data out: %h",m_id,tr.data_out),UVM_LOW)
            end
        end
    endfunction


endclass