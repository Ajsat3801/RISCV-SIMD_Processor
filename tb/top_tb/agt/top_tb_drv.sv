/*  -----------------------------------------------------------------------------------------------
 *                                               Driver
 *  -----------------------------------------------------------------------------------------------
 *  <Todo: additional documentation>
 *
 */

class top_tb_drv extends uvm_driver #(uvm_sequence_item);

    virtual top_tb_if_preload vif;

    `uvm_component_utils(top_tb_drv)

    function new(string name = "top_tb_drv", uvm_component parent = null);
        super.new(name, parent);
    endfunction : new

    //  -------------------------------------------------------------------------------------------
    //                                          Phases
    //  -------------------------------------------------------------------------------------------

    virtual function void build_phase(uvm_phase phase);

        if(!uvm_config_db#(virtual top_tb_if_preload)::get(this, "","vif", vif))
            `uvm_fatal("DRV/NOVIF", "virtual interface vif not set for top_tb_drv")

    endfunction : build_phase

    virtual task run_phase(uvm_phase phase);

        uvm_sequence_item item;

        forever begin
            seq_item_port.get_next_item(item);
            drive_item(item);
            seq_item_port.item_done();
        end

        
    endtask : run_phase

    //  -------------------------------------------------------------------------------------------
    //                                        wrapper tasks
    //  -------------------------------------------------------------------------------------------

    task drive_item(uvm_sequence_item item);
        /*  Wrapper for the functional part of run_phase  
         *  ->  Task that typecasts the item into the appropriate type and dispatches the to 
         *      the DUT through top_tb_if_preload interface
         *  ->  Run for every item in the sequence generated
         */

        top_tb_tr_preload preload_item;
        top_tb_tr_compute compute_item;

        if($cast(preload_item, item)) drive_preload_item(preload_item);
        else if($cast(compute_item, item)) drive_compute_item(compute_item);
        else `uvm_fatal("DRV/BADTYPE", $sformatf("Invalid sequence_item type %s", item.get_type_name()))

    endtask : process_item


    task drive_preload_item(top_tb_tr_preload preload_item);
        // task to unpack transaction and invoke driver BFM method for preloads

        vif.drive_preload(
            .imem_en(preload_item.imem_en),
            .imem_address(preload_item.address),
            .imem_data(preload_item.imem_data),
            .dmem_en(preload_item.dmem_en),
            .dmem_write_enable(preload_item.dmem_write_enable),
            .dmem_address(preload_item.dmem_address),
            .dmem_data(preload_item.dmem_data),
            .sc_prf_en(preload_item.sc_prf_en),
            .sc_prf_data(preload_item.sc_prf_data),
            .sc_prf_address(preload_item.sc_prf_address),
            .vc_prf_en(preload_item.vc_prd_en),
            .vc_prf_data(preload_item.vc_prd_data),
            .vc_prf_address(preload_item.vc_prf_address)
        );

        `uvm_info("DRV", $sformat("Preload_item driven\n%s",item.convert2string()), UVM_DEBUG)

    endtask : drive_preload_item


    task drive_compute_item(top_tb_tr_compute compute_item);
        // task to unpack transaction and invoke driver BFM method for compute

        vif.drive_compute(item.start);

        `uvm_info("DRV", $sformat("Compute_item driven; start = %0b",start),UVM_DEBUG)

    endtask : drive_compute_item


endclass : top_tb_drv