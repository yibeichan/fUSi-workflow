#!/bin/bash

# Move to the appropriate directory
cd /opt/home/output/Florian_preproc/afni

# Log files
stdout_log="output.log"
stderr_log="error.log"

# Original file path
original_file="/opt/home/output/Florian_preproc/afni/reorient/anat_raw.deo.ryf.rf.rs.nii.gz"
new_file="/opt/home/output/Florian_preproc/afni/reorient/anat_refit.nii.gz"

cp "$original_file" "$new_file"
echo "File copied from $original_file to $new_file"

# Run the animal_warper command with the new file path
@animal_warper -input "$new_file" -base /opt/home/data/template_T1w.nii.gz >> "${stdout_log}" 2>> "${stderr_log}"
