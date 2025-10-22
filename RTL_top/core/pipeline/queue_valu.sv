/*
    Decode stage of the 5 stage pipeline
    ->  Decodes the fetched instructions into control signals
    ->  Generate immediate values
    ->  Read source values from the register
    ->  Handle flush from branch
    
    ->  Later
        ->  Hzard detection 
            if next instruction depends on a load still in MEM: add a stall
            else: prepare operands and forward control

*/