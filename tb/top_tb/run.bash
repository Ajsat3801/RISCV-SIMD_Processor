#!/bin/bash
# run.bash — compiles once, then loops ./simv with automatic random seeds

rm -rf csrc simv simv.daidir *.so DVEfiles ucli.key vc_hdrs.h .vcs* AN.DB 2>/dev/null

vcs -full64 -timescale=1ns/1ns +warn=all -sverilog -ntb_opts uvm-1.2 design.sv testbench.sv top_tb_ref_model.cpp -o simv

if [ ! -f ./simv ]; then
    echo "COMPILE FAILED -- no simv produced, check the compile output above"
    exit 1
fi

NUM_RUNS=16
VERBOSITY=UVM_HIGH
LOGDIR=regression_logs
mkdir -p "$LOGDIR"

RED='\033[0;31m'
NC='\033[0m'

for ((i=1; i<=NUM_RUNS; i++)); do
    TMPLOG="${LOGDIR}/tmp_run_${i}.log"

    ./simv +ntb_random_seed_automatic +UVM_VERBOSITY=${VERBOSITY} > "$TMPLOG" 2>&1

    SEED=$(grep -o "Simulator seed:[-0-9]*" "$TMPLOG" | head -1 | cut -d: -f2)
    FINALLOG="${LOGDIR}/run_${VERBOSITY}_S${SEED:-UNKNOWN}.log"
    mv "$TMPLOG" "$FINALLOG"

    printf "%-8s%-20s: " "Run $i" "(seed=$SEED)"
    if grep -q "TEST PASSED" "$FINALLOG"; then
        echo "Run $i (seed=$SEED): PASS"
    else
        echo "Run $i (seed=$SEED): FAIL -- $FINALLOG"
    fi
done

echo "Regression done -- $NUM_RUNS runs, logs in $LOGDIR/"