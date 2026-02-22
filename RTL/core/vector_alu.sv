/*
    Execute stage of the 5 stage pipeline
    ->  Selects operands based on the instruction type
        1) ALU ops : rs1, rs2 and imm
        2) Mem ops : rs1 + imm = address
        3) Jump ops: use Rs1 for comparisons and targets

    ->  <ALU> executes integer opeations
    ->  <Branch Unit> returns target address
    ->  Later
        ->  Forwarding Logic
        ->  handling JAL instructions and all

*/