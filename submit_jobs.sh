#!/bin/bash
# usage: ./submit_jobs.sh <remote_user> <remote_host> <remote_dir>

if [ "$#" -ne 3 ]; then
    echo "usage: $0 <remote_user> <remote_host> <remote_dir>"
    exit 1
fi

REMOTE_USER="$1"
REMOTE_HOST="$2"
REMOTE_DIR="$3"

# prompt for remote password (sshpass required)
read -sp "enter remote password for ${REMOTE_USER}@${REMOTE_HOST}: " REMOTE_PASS
echo ""

echo "ensuring remote directory ${REMOTE_DIR} exists..."
sshpass -p "$REMOTE_PASS" ssh ${REMOTE_USER}@${REMOTE_HOST} "mkdir -p ${REMOTE_DIR}"

# push local files to remote
for file in train.py setup_env.sh submit_jobs.sh check_status.sh; do
    sshpass -p "$REMOTE_PASS" scp "$file" ${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_DIR}/
done

echo "setting up remote environment..."
sshpass -p "$REMOTE_PASS" ssh ${REMOTE_USER}@${REMOTE_HOST} "cd ${REMOTE_DIR} && chmod +x setup_env.sh && ./setup_env.sh"

# create a temporary directory for job scripts locally
TEMP_DIR="temp_scripts"
mkdir -p "$TEMP_DIR"

# define experiments (different hidden-layer setups)
for hidden in "128" "256,128" "512,256,128"; do
    safe_hidden=$(echo $hidden | tr ',' 'x')
    exp_name="exp_${safe_hidden}"
    job_script="${TEMP_DIR}/${exp_name}.sh"

    # create a job script that activates the remote venv before running train.py
    cat <<EOF > "$job_script"
#!/bin/bash
#SBATCH --job-name=test
#SBATCH --partition=gpu-long
#SBATCH --time=5-00:00:00
#SBATCH --cpus-per-gpu=40
#SBATCH --nodes=1
#SBATCH --gres=gpu:h100-96
#SBATCH --mem=200G

cd ${REMOTE_DIR}
touch ${exp_name}.running
source venv/bin/activate
python train.py --hidden ${hidden} --epochs 5 --lr 0.001 --save_model ${exp_name}_model.pth --log_file ${exp_name}_log.txt
rm ${exp_name}.running
touch ${exp_name}.finished
EOF

    # push job script to remote and submit it
    sshpass -p "$REMOTE_PASS" scp "$job_script" ${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_DIR}/
    sshpass -p "$REMOTE_PASS" ssh ${REMOTE_USER}@${REMOTE_HOST} "cd ${REMOTE_DIR} && chmod +x ${exp_name}.sh && sbatch ${exp_name}.sh"
    echo "submitted job for ${exp_name}"
done

echo "all jobs submitted. use: ./check_status.sh ${REMOTE_USER} ${REMOTE_HOST} ${REMOTE_DIR} to monitor progress and pull finished outputs."
