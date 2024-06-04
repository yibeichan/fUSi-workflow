#!/bin/bash                      
#SBATCH --job-name=mri_align 
#SBATCH --output=/om/user/yibei/fUSi-workflow/logs/%x_%j.out 
#SBATCH --error=/om/user/yibei/fUSi-workflow/logs/%x_%j.err 
#SBATCH --partition=normal 
#SBATCH --exclude=node[030-060]
#SBATCH --time=05:00:00
#SBATCH --cpus-per-task=1
#SBATCH --mem=4G
#SBATCH --mail-type=FAIL,END
#SBATCH --mail-user=yibei@mit.edu

source $HOME/.bashrc
source $HOME/miniconda3/etc/profile.d/conda.sh

conda activate neurodocker

module load openmind8/apptainer/1.1.7 

# Define paths
original_input_file="/opt/home/data/charmander/mri/charmander_T1_200um.nii"
base_file="/opt/home/data/template/template_T1w.nii.gz"
atlas_file1="/opt/home/data/atlas/atlas_MBM_cortex_vH.nii"
atlas_file2="/opt/home/data/atlas/atlas_MBM_subcortical_beta.nii"
skullstrip_file="/opt/home/data/template/mask_brain.nii.gz"
output_dir="/opt/home/output/charmander/preproc/aw_results_mri"
reoriented_output_dir="/opt/home/output/charmander/preproc/reorient"

apptainer run -B /om/user/yibei/fUSi-workflow:/opt/home -e /om/user/yibei/images/afni.sif \
    /opt/home/code/bash/afni_preproc.sh -i "$original_input_file" -b "$base_file" -a "$atlas_file1" "$atlas_file2" -s "$skullstrip_file" -o "$output_dir" -r "$reoriented_output_dir"