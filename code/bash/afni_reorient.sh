#!/bin/bash
fullpath_file="/opt/home/data/Florian_raw_data/14_MEAN_S12_S13_1.nii"
output_dir="/opt/home/output/Florian_preproc/afni/reorient"

# Log files
stdout_log="${output_dir}/output.log"
stderr_log="${output_dir}/error.log"

# # Ensure the output directory exists
# mkdir -p "${output_dir}"

# Change directory
cd "${output_dir}"

# Deoblique
temp_prefix=anat_raw.deo
3dWarp -oblique2card -prefix "${temp_prefix}.nii.gz" "${fullpath_file}" >> "${stdout_log}" 2>> "${stderr_log}"

# Flip Sphinx position
temp_input="${temp_prefix}"
temp_prefix="${temp_prefix}.ryf"
3dLRflip -Y -prefix "${temp_prefix}.nii.gz" "${temp_input}.nii.gz" >> "${stdout_log}" 2>> "${stderr_log}"

# Re-orient position
temp_input="${temp_prefix}"
temp_prefix="${temp_prefix}.rf"
3dcopy "${temp_input}.nii.gz" "${temp_prefix}.nii.gz" >> "${stdout_log}" 2>> "${stderr_log}"

# Refit orientation (check if this is needed in Flip Sphinx position)
3drefit -orient LIP "${temp_prefix}.nii.gz" >> "${stdout_log}" 2>> "${stderr_log}"

# Resample
temp_input="${temp_prefix}"
temp_prefix="${temp_prefix}.rs"
3dresample -orient LPI -prefix "${temp_prefix}.nii.gz" -input "${temp_input}.nii.gz" >> "${stdout_log}" 2>> "${stderr_log}"
