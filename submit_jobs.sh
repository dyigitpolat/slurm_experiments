#!/bin/bash
# usage: ./submit_jobs.sh <remote_user> <remote_host> <remote_dir>
if [ "$#" -ne 3 ]; then
    echo "usage: $0 <remote_user> <remote_host> <remote_dir>"
    exit 1
fi

REMOTE_USER="$1"
REMOTE_HOST="$2"
REMOTE_DIR="$3"

# source configuration and grid helper
source config.sh
source grid_expand.sh

# determine experiments: use explicit list if provided; otherwise, expand GRID_PARAMS
if [ ${#EXPERIMENTS_LIST[@]} -ne 0 ]; then
    EXPERIMENTS=("${EXPERIMENTS_LIST[@]}")
else
    EXPERIMENTS=($(grid_expand "${GRID_PARAMS[@]}"))
fi

# prompt for remote password (sshpass required)
read -sp "enter remote password for ${REMOTE_USER}@${REMOTE_HOST}: " REMOTE_PASS
echo ""

echo "ensuring remote directory ${REMOTE_DIR} exists..."
sshpass -p "$REMOTE_PASS" ssh ${REMOTE_USER}@${REMOTE_HOST} "mkdir -p ${REMOTE_DIR}"

# push files defined in config to remote
for file in "${FILES_TO_PUSH[@]}"; do
    sshpass -p "$REMOTE_PASS" scp "$file" ${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_DIR}/
done

echo "setting up remote environment..."
sshpass -p "$REMOTE_PASS" ssh ${REMOTE_USER}@${REMOTE_HOST} "cd ${REMOTE_DIR} && chmod +x setup_env.sh && ./setup_env.sh"

# create a temporary directory locally for job scripts
TEMP_DIR="temp_scripts"
mkdir -p "$TEMP_DIR"

# iterate over experiments
for experiment in "${EXPERIMENTS[@]}"; do
    # create a safe experiment id (replace commas and equals with underscores)
    safe_experiment=$(echo "$experiment" | tr ',' '_' | tr '=' '_')
    exp_name="exp_${safe_experiment}"
    job_script="${TEMP_DIR}/${exp_name}.sh"
    
    # substitute placeholders in RUN_CMD using experiment parameters
    job_cmd="$RUN_CMD"
    IFS=',' read -ra pairs <<< "$experiment"
    for pair in "${pairs[@]}"; do
        key=${pair%%=*}
        value=${pair#*=}
        job_cmd=$(echo "$job_cmd" | sed "s/{${key}}/${value}/g")
    done
    # substitute {exp_name} in the command
    job_cmd=$(echo "$job_cmd" | sed "s/{exp_name}/${exp_name}/g")
    
    # substitute {exp_name} in SBATCH_DIRECTIVES
    job_sbatch=$(echo "$SBATCH_DIRECTIVES" | sed "s/{exp_name}/${exp_name}/g")
    
    # generate the job script with the substituted SBATCH directives and command
    cat <<EOF > "$job_script"
#!/bin/bash
$job_sbatch

cd ${REMOTE_DIR}
rm ${exp_name}.pending
touch ${exp_name}.running
${job_cmd}
rm ${exp_name}.running
touch ${exp_name}.finished
EOF

    # indicate job is submitted and pending at remote
    sshpass -p "$REMOTE_PASS" ssh ${REMOTE_USER}@${REMOTE_HOST} "cd ${REMOTE_DIR} && touch ${exp_name}.pending"
    
    # push the job script and submit it remotely
    sshpass -p "$REMOTE_PASS" scp "$job_script" ${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_DIR}/
    sshpass -p "$REMOTE_PASS" ssh ${REMOTE_USER}@${REMOTE_HOST} "cd ${REMOTE_DIR} && chmod +x ${exp_name}.sh && sbatch ${exp_name}.sh"
    echo "submitted job for ${exp_name}"
done

echo "all jobs submitted. to monitor progress and retrieve outputs, run:"
echo "  ./check_status.sh ${REMOTE_USER} ${REMOTE_HOST} ${REMOTE_DIR}"
