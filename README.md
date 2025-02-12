# slurm experiments with custom grid expansion

this repo provides a modular, no-fuss setup for running your pytorch experiments on a slurm cluster. it's built to let you easily run grid experiments (or any other parameter combinations) without drowning in boilerplate.

## files

- **train.py**  
  your pytorch training script (set up for mnist by default). feel free to tweak it for your needs.

- **grid_expand.sh**  
  an internal helper that expands parameter grids into experiment configurations. it's hidden—no need to mess with it.

- **config.sh**  
  the declarative hub for your experiments. here you define:
  - **GRID_PARAMS**: a dictionary-like array where each element is in the format `key:val1,val2,...`. for example, `"lr:0.1,0.01,0.001"` and `"epochs:1,2,5,10"`.
  - **EXPERIMENTS_LIST**: (optional) an explicit list of experiments. if left empty, experiments are generated via grid expansion.
  - **SBATCH_DIRECTIVES**: your custom sbatch header lines. you can use `{exp_name}` to automatically insert the experiment name.
  - **RUN_CMD**: the command template for each job. use placeholders like `{lr}`, `{epochs}`, and `{exp_name}`.
  - files to push and fetch.

- **setup_env.sh**  
  sets up a remote virtual environment and installs dependencies (torch, torchvision, etc.).

- **submit_jobs.sh**  
  pushes files to your remote machine, sets up the environment, generates job scripts (using grid expansion) in a local `temp_scripts` folder, and submits jobs to slurm.

- **check_status.sh**  
  polls remote job markers, downloads finished outputs into a local `temp_results` folder, and shows currently running experiments.

## prerequisites

- linux/mac (or wsl on windows) with bash
- python3 (3.7+ recommended)
- access to a slurm cluster (ssh)
- [sshpass](https://linux.die.net/man/1/sshpass) installed locally (for non-interactive password passing)

## usage

1. **configure your experiments**  
   edit `config.sh`:
   - adjust **GRID_PARAMS** to define your experiment parameter grid.
   - optionally set **EXPERIMENTS_LIST** if you prefer to list experiments explicitly.
   - customize **SBATCH_DIRECTIVES** and **RUN_CMD** as needed.
   - update file lists if necessary.

2. **make scripts executable**
   ```bash
   chmod +x *.sh
   ```

3. **submit experiments**
   ```bash
   ./submit_jobs.sh <remote_user> <remote_host> <remote_dir>
   ```
   for example:
   ```bash
   ./submit_jobs.sh my_user slurm.example.com ~/experiments
   ```
   you'll be prompted for your remote password. this script pushes all necessary files, sets up the remote environment, generates job scripts (stored locally in `temp_scripts`), and submits your experiments.

4. **monitor and retrieve outputs**
   ```bash
   ./check_status.sh <remote_user> <remote_host> <remote_dir>
   ```
   finished experiment outputs will be downloaded into the local `temp_results` folder.

## customization

- **grid expansion**: adjust **GRID_PARAMS** in `config.sh` (each element should be in the format `key:val1,val2,...`). the helper in `grid_expand.sh` generates all parameter combinations.
- **command template**: modify **RUN_CMD** in `config.sh` to change how each job is executed. use placeholders (e.g. `{lr}`, `{epochs}`, `{exp_name}`) that get replaced based on your experiment parameters.
- **SBATCH directives**: customize **SBATCH_DIRECTIVES** in `config.sh` to define your slurm header lines explicitly. use `{exp_name}` to automatically insert the experiment name.
- **file transfers**: update **FILES_TO_PUSH** and **FILES_TO_FETCH** in `config.sh` if you need to push or fetch additional files.

## tl;dr

1. edit `config.sh` to set your experiments  
2. run:
   ```bash
   ./submit_jobs.sh my_user slurm.example.com ~/experiments
   ./check_status.sh my_user slurm.example.com ~/experiments
   ```