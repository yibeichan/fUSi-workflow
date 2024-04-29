#!/bin/bash

# Move to the appropriate directory
cd /opt/home/output/Florian_preproc/afni

# Log files
stdout_log="output_angio_aw.log"
stderr_log="error_angio_aw.log"

# Original file path
# original_file="/opt/home/output/Florian_preproc/afni/reorient/anat_raw.deo.ryf.rf.rs.nii.gz"
input_file="/opt/home/output/Florian_preproc/afni/reorient_angio/angio_raw_deo_ryf_rf_rs.nii.gz"
# new_file="/opt/home/output/Florian_preproc/afni/reorient_angio/angio_raw_deo_ryf_rf_rs.nii.gz"

# cp "$original_file" "$new_file"
# echo "File copied from $original_file to $new_file"

# Run the animal_warper command with the new file path
@animal_warper -input "$input_file" -base /opt/home/data/template_T1w.nii.gz -outdir /opt/home/output/Florian_preproc/afni/aw_results_angio -skullstrip /opt/home/data/mask_brain.nii.gz >> "${stdout_log}" 2>> "${stderr_log}"
