#!/bin/bash                      
#SBATCH --job-name=mri_align 
#SBATCH --output=/om/user/yibei/fUSi-workflow/logs/%x_%j.out 
#SBATCH --error=/om/user/yibei/fUSi-workflow/logs/%x_%j.err 
#SBATCH --partition=normal 
#SBATCH --exclude=node[030-060]
#SBATCH --time=06:00:00
#SBATCH --cpus-per-task=1
#SBATCH --mem=16G
#SBATCH --mail-type=FAIL,END
#SBATCH --mail-user=yibei@mit.edu

source $HOME/.bashrc
source $HOME/miniconda3/etc/profile.d/conda.sh

conda activate neurodocker

module load openmind8/apptainer/1.1.7 

apptainer run -B /om/user/yibei/fUSi-workflow:/opt/home -e /om/user/yibei/images/afni.sif /opt/home/code/bash/mri2template.sh
