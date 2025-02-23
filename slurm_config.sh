#!/bin/bash
# slurm_config.sh: experiment configuration.
# define grid parameters as a dictionary-like array.
# each element is of the form "key:val1,val2,..."
declare -a GRID_PARAMS=("lr:0.1,0.01,0.001" "epochs:1,2,5,10")

# if you prefer to list experiments explicitly, set EXPERIMENTS_LIST.
# if left empty, experiments are generated via grid expansion.
# e.g.:
# EXPERIMENTS_LIST=(
#   "lr=0.1,epochs=1"
#   "lr=0.001,epochs=10"
# )
EXPERIMENTS_LIST=()

# custom SBATCH directives: define your #SBATCH lines explicitly.
# you can use {exp_name} to automatically insert the experiment name.
SBATCH_DIRECTIVES="
#SBATCH --job-name={exp_name}
#SBATCH --partition=gpu
#SBATCH --time=00:10:00
#SBATCH --cpus-per-gpu=40
#SBATCH --nodes=1
#SBATCH --gres=gpu:h100-47:1
#SBATCH --mem=200G"

# command template (use placeholders like {lr}, {epochs}, and {exp_name})
RUN_CMD="
source venv/bin/activate
python train.py --lr {lr} --epochs {epochs} --save_model {exp_name}_model.pth --log_file {exp_name}_log.txt"

# files to push to remote
FILES_TO_PUSH=(
    "train.py" 
    "slurm_setup_env.sh" 
    "slurm_submit_jobs.sh" 
    "slurm_check_status.sh" 
    "slurm_config.sh" 
    "slurm_grid_expand.sh" 
    "requirements.txt"
)

# files to fetch from remote (use {exp_name} as placeholder)
FILES_TO_FETCH=(
    "{exp_name}_model.pth" 
    "{exp_name}_log.txt"
)
