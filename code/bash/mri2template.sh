#!/bin/bash

# Log files
stdout_log="/opt/home/output/charmander/preproc/aw_results_mri/output_mri_aw.log"
stderr_log="/opt/home/output/charmander/preproc/aw_results_mri/error_mri_aw.log"

# Define input and output files
input_file="/opt/home/data/charmander/mri/charmander_T1_200um.nii"
base_file="/opt/home/data/template/template_T1w.nii.gz"
skullstrip_file="/opt/home/data/template/mask_brain.nii.gz"
output_dir="/opt/home/output/charmander/preproc/aw_results_mri"

# Run the animal_warper command with the new file path
@animal_warper -input "$input_file" -base "$base_file" -outdir "$output_dir" -skullstrip "$skullstrip_file" -ok_to_exist >> "${stdout_log}" 2>> "${stderr_log}"