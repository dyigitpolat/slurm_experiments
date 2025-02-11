# slurm experiments with param neural nets

this repo is a quick & dirty setup to run pytorch mnist experiments with flexible architectures on a slurm cluster. it's got everything you need to set up a remote venv, submit jobs, track their status with marker files, and auto-pull finished outputs.

## project structure

- **train.py**  
  a pytorch script that builds & trains a neural net on mnist. you can pass different hidden-layer setups via the `--hidden` argument.

- **setup_env.sh**  
  sets up a python virtual environment on the remote machine and installs dependencies. it installs packages from `requirements.txt` if available, otherwise defaults to installing `torch` and `torchvision`.

- **submit_jobs.sh**  
  pushes files to the remote machine, sets up the remote environment, and submits jobs to slurm.  
  **usage:**  
  ```bash
  ./submit_jobs.sh <remote_user> <remote_host> <remote_dir>
  ```  
  uses `sshpass` so you only enter your remote password once.

- **check_status.sh**  
  checks remote marker files to see which jobs are running or finished, then retrieves logs & models for finished jobs.  
  **usage:**  
  ```bash
  ./check_status.sh <remote_user> <remote_host> <remote_dir>
  ```

- **requirements.txt**  
  lists the python dependencies for the training script. update this file with additional packages as needed.

## prerequisites

- local & remote: python3 (3.7+ recommended)
- pytorch & torchvision (see `requirements.txt`)
- ssh access to your slurm login node
- `sshpass` installed locally (for non-interactive ssh/scp with password)

## usage

1. **update remote details:**  
   the scripts require you to pass remote username, host, and experiments directory as arguments. for example:
   ```bash
   ./submit_jobs.sh my_user slurm.example.com ~/my_experiments
   ./check_status.sh my_user slurm.example.com ~/my_experiments
   ```

2. **make scripts executable:**
   ```bash
   chmod +x *.sh
   ```

3. **(optional) update requirements:**  
   update the `requirements.txt` with any additional packages you need on the remote machine.

4. **submit experiments:**  
   run:
   ```bash
   ./submit_jobs.sh <remote_user> <remote_host> <remote_dir>
   ```  
   you'll be prompted for your remote password. this pushes files to the remote machine, sets up the virtual environment, and submits your jobs (each job creates `.running` and `.finished` marker files).

5. **monitor & retrieve outputs:**  
   run:
   ```bash
   ./check_status.sh <remote_user> <remote_host> <remote_dir>
   ```  
   this shows which experiments are still running and pulls finished logs/models to your local folder.

## notes

- experiment parameters (like hidden-layer sizes) are defined in `submit_jobs.sh` — edit as needed.
- job settings (time, mem, cpus) are in the auto-generated job scripts within `submit_jobs.sh`. adjust if necessary.
- marker files (`*.running`, `*.finished`) track job state on the remote.
- ensure `sshpass` is installed on your local system (e.g. via your package manager).

## tl;dr

- run `./submit_jobs.sh <remote_user> <remote_host> <remote_dir>` to push and submit your experiments.
- run `./check_status.sh <remote_user> <remote_host> <remote_dir>` to monitor progress and auto-download finished outputs.
