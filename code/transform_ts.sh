#!/bin/bash

#SBATCH --job-name=transform_ts
#SBATCH --partition=normal
#SBATCH --output=../logs/transform_ts_%j.out
#SBATCH --error=../logs/transform_ts_%j.err
#SBATCH --time=08:00:00
#SBATCH --cpus-per-task=16
#SBATCH --mem=40G
#SBATCH --array=0
#SBATCH --mail-type=FAIL,END
#SBATCH --mail-user=yibei@mit.edu

source $HOME/miniconda3/etc/profile.d/conda.sh

# Activate your Conda environment
conda activate fusi

python transform_ts.py