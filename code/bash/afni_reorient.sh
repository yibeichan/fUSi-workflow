#!/bin/bash
# fullpath_file="/opt/home/data/Florian_raw_data/15_NoSAT_TOF_3D_multi-slab_0.13mm_iso.nii"
fullpath_file="/opt/home/data/Charmander_withouskull_withMB_3Dscan_4_angio3D.nii"
output_dir="/opt/home/output/Florian_preproc/afni/reorient_fusi"

mkdir -p "${output_dir}"

# Log files
stdout_log="${output_dir}/output.log"
stderr_log="${output_dir}/error.log"

# Change directory
cd "${output_dir}"

# Deoblique
temp_prefix=fusi_raw_deo
3dWarp -oblique2card -prefix "${temp_prefix}.nii.gz" "${fullpath_file}" >> "${stdout_log}" 2>> "${stderr_log}"

# Flip Sphinx position
temp_input="${temp_prefix}"
temp_prefix="${temp_prefix}_ryf"
3dLRflip -Y -prefix "${temp_prefix}.nii.gz" "${temp_input}.nii.gz" >> "${stdout_log}" 2>> "${stderr_log}"

# Re-orient position
temp_input="${temp_prefix}"
temp_prefix="${temp_prefix}_rf"
3dcopy "${temp_input}.nii.gz" "${temp_prefix}.nii.gz" >> "${stdout_log}" 2>> "${stderr_log}"

# Refit orientation (check if this is needed in Flip Sphinx position)
3drefit -orient LIP "${temp_prefix}.nii.gz" >> "${stdout_log}" 2>> "${stderr_log}"

# Resample
temp_input="${temp_prefix}"
temp_prefix="${temp_prefix}_rs"
3dresample -orient LPI -prefix "${temp_prefix}.nii.gz" -input "${temp_input}.nii.gz" >> "${stdout_log}" 2>> "${stderr_log}"
