#!/bin/bash
#SBATCH --account=st-sdonner-1
#SBATCH --job-name=loo_array
#SBATCH --partition=cascade
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=28
#SBATCH --mem=128G
#SBATCH --time=24:00:00
#SBATCH --array=1-4
#SBATCH --output=output/post_peak_model/loo_%A_%a.out
#SBATCH --error=output/post_peak_model/loo_%A_%a.err
#SBATCH --mail-type=END,FAIL
#SBATCH --mail-user=virginie.bornarel@ubc.ca

# --- Initialize environment ---
source /etc/profile.d/modules.sh
module load gcc/9.4.0
module load r/4.4.0
module load r-dplyr

# --- Ensure R uses my home library ---
export R_LIBS_USER=/arc/home/vbornare/R/x86_64-pc-linux-gnu-library/4.4

# --- Move to project directory ---
cd $SLURM_SUBMIT_DIR

echo "Running LOO for model ID $SLURM_ARRAY_TASK_ID on $(hostname) at $(date)"
which Rscript
Rscript --version

# --- Run script ---
Rscript scripts/post_peak_model/run_loo_checks.R $SLURM_ARRAY_TASK_ID

echo "Finished at $(date)"
