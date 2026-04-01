
class rs_slot_freeq_1push_scb extends uvm_scoreboard;

    `uvm_component_utils(rs_slot_freeq_1push_scb)

    uvm_analysis_imp #(rs_slot_freeq_1push_tr, rs_slot_freeq_1push_scb) mon_imp;
    rs_slot_freeq_1push_ref_model_adapter ref_model;

    bit stimulus_done_flag = 1'b0;
    bit check_done_flag = 1'b0;
    event check_done_ev;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    task done();
        if(!check_done_flag) @check_done_ev;
    endtask

    function void stimulus_done();
        stimulus_done_flag = 1'b1;
    endfunction

    task update_scoreboard_status();
        if(stimulus_done_flag && !check_done_flag) begin
            check_done_flag = 1'b1;
            -> check_done_ev;
        end
    endtask

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        mon_imp = new("mon_imp", this);
        ref_model = new();
        ref_model.create_model();
    
    endfunction

    virtual task write(rs_slot_freeq_1push_tr tr);

        T data_out;
        bit full, empty;
        bit pass;
        string msg;

        ref_model.run_model(
            .push_dataT(tr.push_data),
            .push(tr.push),
            .pop(tr.pop),
            .reset_n(tr.reset_n),
            .data_outT(data_out),
            .full(full),
            .empty(empty)
        );

        msg = {
            $sformatf("\t|data_in: %h\t|psh: %0d\t|pop: %0d\t||",tr.push_data, tr.push, tr.pop),
            $sformatf("exp_out: %h\t|act_out: %h\t||",data_out, tr.data_out),
            $sformatf("exp_empty: %0d\t|act_empty: %0d\t||",empty, tr.empty),
            $sformatf("exp_full: %0d\t|act_full:%0d", full, tr.full)
        };

        pass = (tr.data_out == data_out) && (tr.full == full) && (tr.empty == empty);

        if(pass) begin
            `uvm_info("SCB_MATCH", msg, UVM_MEDIUM)
        end else begin
        `uvm_error("SCB_ERROR", msg)
        end

        update_scoreboard_status();
    endtask


endclass