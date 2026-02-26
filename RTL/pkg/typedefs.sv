/*
    type defs for decoded instructions
*/

package instr_desc;

    localparam REG_W = 32;
    localparam ROB_W = 32;
    localparam REG_ADDR_W = $clog2(REG_W);
    localparam ROB_ADDR_W = $clog2(ROB_W);

    typedef enum logic {IDLE, BUSY} decode_state_e;
    typedef enum logic {SALU, SMULDIV} wb_state_e;

    

    

    

    

    

    



    // typedefs for scalar muldiv, vector alu, vector muldiv remaining
endpackage