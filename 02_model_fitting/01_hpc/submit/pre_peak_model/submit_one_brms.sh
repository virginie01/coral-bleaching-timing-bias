#!/bin/bash
#SBATCH --account=st-sdonner-1
#SBATCH --job-name=brms_single
#SBATCH --time=48:00:00
#SBATCH --mem=64G
#SBATCH --cpus-per-task=4
#SBATCH --output=output/pre_peak_model/brms_single_%j.out
#SBATCH --error=output/pre_peak_model/brms_single_%j.err
#SBATCH --mail-type=END,FAIL
#SBATCH --mail-user=virginie.bornarel@ubc.ca

module load R/4.5.0
cd $SLURM_SUBMIT_DIR

Rscript scripts/pre_peak_model/run_one_brms_model.R
