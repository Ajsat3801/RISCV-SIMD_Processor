/*
    Memory stage of the 5 stage pipeline
    ->  If no memory operation then forward the ALU result unchanged
    ->  If store then write to DMEM
    ->  if Load then 
        Cycle 1) Read from DMEM
        Cycle 2) align and extend loaded data
    ->  Later
        ->  JAL/ JALR handling
        ->  Hazard handling
*/