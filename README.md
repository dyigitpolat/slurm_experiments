# simple slurm experiment runner

this setup lets you run grid experiments on a slurm cluster with minimal hassle.

## what to change

- **config.sh**
  - **GRID_PARAMS**: update these to define your experiment parameters. for example:
    - `("lr:0.1,0.01,0.001" "epochs:1,2,5,10")`
  - **SBATCH_DIRECTIVES**: customize your slurm header lines (e.g. time, mem, etc). you can use `{exp_name}` as a placeholder.
  - **RUN_CMD**: change the command that runs your experiment. use placeholders like `{lr}`, `{epochs}`, and `{exp_name}`.
  - **FILES_TO_PUSH/FILES_TO_FETCH**: adjust if you need to send or retrieve extra files.

- **setup_env.sh**
  - modify this file if you need to install extra dependencies on the remote machine. by default it installs torch and torchvision.

## what to run

1. **make scripts executable**  
   ```bash
   chmod +x *.sh
   ```

2. **submit your experiments**  
   run:
   ```bash
   ./submit_jobs.sh <remote_user> <remote_host> <remote_dir>
   ```
   _example_:  
   ```bash
   ./submit_jobs.sh my_user slurm.example.com ~/experiments
   ```
   you'll be prompted for your remote password.

3. **check status and retrieve outputs**  
   run:
   ```bash
   ./check_status.sh <remote_user> <remote_host> <remote_dir>
   ```
   _example_:  
   ```bash
   ./check_status.sh my_user slurm.example.com ~/experiments
   ```
   finished outputs will download into a local `temp_results` folder.

## prerequisites

- bash (linux/mac or wsl)
- sshpass (for password passing)
- access to a slurm cluster via ssh