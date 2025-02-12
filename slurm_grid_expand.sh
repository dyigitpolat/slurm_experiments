#!/bin/bash
# slurm_grid_expand.sh: internal helper for expanding parameter grids.
# usage: slurm_grid_expand "key1:val1,val2,..." "key2:val1,val2,..."
slurm_grid_expand() {
    local arr=("$@")
    local result=("")
    for entry in "${arr[@]}"; do
         local key=${entry%%:*}
         local vals=${entry#*:}
         IFS=',' read -ra values <<< "$vals"
         local new_result=()
         for r in "${result[@]}"; do
             for v in "${values[@]}"; do
                 if [ -z "$r" ]; then
                     new_result+=("${key}=${v}")
                 else
                     new_result+=("${r},${key}=${v}")
                 fi
             done
         done
         result=("${new_result[@]}")
    done
    echo "${result[@]}"
}
