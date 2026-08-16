// UVM object to maintain run status
// global and can be accessed by any component/object

class top_tb_run_status extends uvm_object;

    bit complete;
    bit snapshot_taken;

    int unsigned retire_count;
    int unsigned idle_cycles;

    uvm_event ev_dut_complete;
    uvm_event ev_check_complete;

    `uvm_object_utils(top_tb_run_status)

    function new(string name = "top_tb_run_status");
        super.new(name);
        ev_dut_complete = new("ev_dut_complete");
        ev_check_complete = new("ev_check_complete");

    endfunction : new

    function string convert2string();
        return $sformatf("complete=%0b snapshot_taken=%0b retires=%0d idle=%0d",
                         complete, snapshot_taken, retire_count, idle_cycles);
    endfunction : convert2string

endclass : top_tb_run_status