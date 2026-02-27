/*
    has 3 fields, Reg, value and ready

    For branch and Jump, target address calculated in decode and stored directly
    for branch, taken/not taken is stored in rd[0]
    
    connections: WB arbiter through CDB, branching from ALU

*/