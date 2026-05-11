#!/bin/bash
#SBATCH --account=st-sdonner-1
#SBATCH --job-name=loo_single
#SBATCH --partition=cascade
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=28
#SBATCH --mem=128G
#SBATCH --time=24:00:00
#SBATCH --output=output/pre_peak_model/loo_single_%j.out
#SBATCH --error=output/pre_peak_model/loo_single_%j.err
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

echo "Running LOO for single model on $(hostname) at $(date)"
which Rscript
Rscript --version

# --- Run script ---
Rscript scripts/pre_peak_model/run_one_loo_checks.R

echo "Finished at $(date)"
