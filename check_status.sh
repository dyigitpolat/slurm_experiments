#!/bin/bash
# usage: ./check_status.sh <remote_user> <remote_host> <remote_dir>
if [ "$#" -ne 3 ]; then
    echo "usage: $0 <remote_user> <remote_host> <remote_dir>"
    exit 1
fi

REMOTE_USER="$1"
REMOTE_HOST="$2"
REMOTE_DIR="$3"

# source config for FILES_TO_FETCH definitions
source config.sh

read -sp "enter remote password for ${REMOTE_USER}@${REMOTE_HOST}: " REMOTE_PASS
echo ""

RESULTS_DIR="temp_results"
mkdir -p "$RESULTS_DIR"

echo "fetching remote job markers..."
status=$(sshpass -p "$REMOTE_PASS" ssh ${REMOTE_USER}@${REMOTE_HOST} "cd ${REMOTE_DIR} && ls -1 *.running *.finished 2>/dev/null")
if [ -z "$status" ]; then
    echo "no job markers found on remote."
else
    echo "$status"
fi

finished_jobs=$(sshpass -p "$REMOTE_PASS" ssh ${REMOTE_USER}@${REMOTE_HOST} "cd ${REMOTE_DIR} && ls -1 *.finished 2>/dev/null")
if [ -n "$finished_jobs" ]; then
    echo "retrieving outputs for finished experiments:"
    for finished in $finished_jobs; do
        base=$(basename "$finished" .finished)
        echo "retrieving files for ${base}..."
        for pattern in "${FILES_TO_FETCH[@]}"; do
            file_to_fetch=$(echo "$pattern" | sed "s/{exp_name}/${base}/g")
            sshpass -p "$REMOTE_PASS" scp ${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_DIR}/${file_to_fetch} "$RESULTS_DIR/"
        done
        sshpass -p "$REMOTE_PASS" ssh ${REMOTE_USER}@${REMOTE_HOST} "rm ${REMOTE_DIR}/${base}.finished"
    done
    echo "outputs retrieved in ${RESULTS_DIR}"
else
    echo "no finished experiments yet."
fi

running_jobs=$(sshpass -p "$REMOTE_PASS" ssh ${REMOTE_USER}@${REMOTE_HOST} "cd ${REMOTE_DIR} && ls -1 *.running 2>/dev/null")
if [ -n "$running_jobs" ]; then
    echo "currently running experiments:"
    echo "$running_jobs"
else
    echo "no running experiments."
fi
