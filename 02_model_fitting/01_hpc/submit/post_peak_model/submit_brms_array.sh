#!/bin/bash
#SBATCH --account=st-sdonner-1
#SBATCH --job-name=brms_array
#SBATCH --partition=cascade
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --time=48:00:00
#SBATCH --mem=96G
#SBATCH --cpus-per-task=4
#SBATCH --array=1-4
#SBATCH --output=output/post_peak_model/post_peak_brms_%A_%a.out
#SBATCH --error=output/post_peak_model/post_peak_brms_%A_%a.err
#SBATCH --mail-type=END,FAIL
#SBATCH --mail-user=virginie.bornarel@ubc.ca

# -------------------------------
# Environment setup
# -------------------------------
source /etc/profile.d/modules.sh

module load gcc/9.4.0
module load r/4.4.0
module load r-dplyr

# Ensure R sees your personal library
export R_LIBS_USER=/arc/home/vbornare/R/x86_64-pc-linux-gnu-library/4.4

# -------------------------------
# Move to project directory
# -------------------------------
cd $SLURM_SUBMIT_DIR

echo "============================================"
echo "Running task ID: $SLURM_ARRAY_TASK_ID"
echo "Node: $(hostname)"
echo "Start time: $(date)"
echo "Working directory: $(pwd)"
echo "============================================"

which Rscript
Rscript --version

# -------------------------------
# Run the model
# -------------------------------
Rscript scripts/post_peak_model/run_brms_model.R $SLURM_ARRAY_TASK_ID

echo "============================================"
echo "Finished task ID: $SLURM_ARRAY_TASK_ID"
echo "End time: $(date)"
echo "============================================"
