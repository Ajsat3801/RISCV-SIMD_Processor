/*  
    Fetch stage of the 5 stage pipeline
    ->  Holds and updates the Program Counter
    ->  Issues read request to the IMEM
    ->  Captures the fetched instruction from IMEM to next stage
    ->  Chooses next PC
        ->  if branch them replaces PC with branch target
        ->  else PC = PC+4
*/