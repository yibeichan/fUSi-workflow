strip_extension() {
    local filename="$1"
    filename=$(basename "$filename")  # Get the base name
    if [[ "$filename" == *.nii.gz ]]; then
        echo "${filename%.nii.gz}"
    elif [[ "$filename" == *.nii ]]; then
        echo "${filename%.nii}"
    else
        echo "$filename"
    fi
}

# input_file="/Users/yibeichen/Desktop/fusi/mri_unna/unna_mri_DSPH_RSA+orig"

input_file="/Users/yibeichen/Desktop/fusi/mri_unna/unna_11_copy.nii"
# preproc_dir="/Users/yibeichen/Desktop/fusi/mri_unna/preproc_unna"
base_file="/Users/yibeichen/Desktop/fusi/atlas/template_T1w.nii.gz"
output_dir="/Users/yibeichen/Desktop/fusi/mri_unna/aw_results6"
skullstrip_file="/Users/yibeichen/Desktop/fusi/atlas/mask_brain.nii.gz"

# Define log files
stdout_log="${output_dir}/animal_warper_stdout.log"
stderr_log="${output_dir}/animal_warper_stderr.log"

original_input_file="$input_file"

# mkdir -p "$preproc_dir"
mkdir -p "$output_dir"
echo "Created output directory: $output_dir" >> "${stdout_log}"

echo "Starting processing pipeline..." >> "${stdout_log}"
echo "Input file: $input_file" >> "${stdout_log}"
echo "Output directory: $output_dir" >> "${stdout_log}"
echo "Preprocessing directory: $preproc_dir" >> "${stdout_log}"

# # Check if input file is oblique using 3dinfo
# is_oblique=0
# if [ "$(3dinfo -is_oblique "$input_file")" != "0" ]; then
#     is_oblique=1
# fi

# if [ "$is_oblique" -eq 1 ]; then
#     echo "Input file is oblique. Using adjunct_deob_around_origin to handle obliquity." >> "${stdout_log}"
    
#     base_filename=$(strip_extension "$original_input_file")
#     temp_prefix="${base_filename}_deob"
#     echo "Base filename: $base_filename" >> "${stdout_log}"
#     echo "Temp prefix: $temp_prefix" >> "${stdout_log}"
    
#     # Run adjunct_deob_around_origin
#     echo "Running adjunct_deob_around_origin..." >> "${stdout_log}"
#     if ! adjunct_deob_around_origin -input "${original_input_file}" -prefix "${preproc_dir}/${temp_prefix}" >> "${stdout_log}" 2>> "${stderr_log}"; then
#         echo "ERROR: adjunct_deob_around_origin failed" >> "${stderr_log}"
#         exit 1
#     fi
    
#     # List files in output directory for debugging
#     echo "Files in preprocessing directory:" >> "${stdout_log}"
#     ls -l "${preproc_dir}" >> "${stdout_log}"
    
#     # Check for AFNI format first (most likely output)
#     if [ -f "${preproc_dir}/${temp_prefix}+orig.HEAD" ]; then
#         echo "Found AFNI format file, converting to NIFTI..." >> "${stdout_log}"
#         # Convert AFNI to NIFTI
#         if ! 3dAFNItoNIFTI -prefix "${preproc_dir}/${temp_prefix}" "${preproc_dir}/${temp_prefix}+orig" >> "${stdout_log}" 2>> "${stderr_log}"; then
#             echo "ERROR: Failed to convert AFNI to NIFTI" >> "${stderr_log}"
#             exit 1
#         fi
#         # Wait for file to be created
#         sleep 1
#     fi
    
#     # Now check for NIFTI files
#     if [ -f "${preproc_dir}/${temp_prefix}.nii.gz" ]; then
#         input_file="${preproc_dir}/${temp_prefix}.nii.gz"
#     elif [ -f "${preproc_dir}/${temp_prefix}.nii" ]; then
#         input_file="${preproc_dir}/${temp_prefix}.nii"
#     else
#         echo "ERROR: Could not find output file. Checked for:" >> "${stderr_log}"
#         echo "  - ${preproc_dir}/${temp_prefix}.nii.gz" >> "${stderr_log}"
#         echo "  - ${preproc_dir}/${temp_prefix}.nii" >> "${stderr_log}"
#         echo "  - ${preproc_dir}/${temp_prefix}+orig.HEAD" >> "${stderr_log}"
#         echo "Directory contents:" >> "${stderr_log}"
#         ls -l "${preproc_dir}" >> "${stderr_log}"
#         exit 1
#     fi
    
#     echo "Using deobliqued file: $input_file" >> "${stdout_log}"
# else
#     echo "Input file is not oblique. No deobliquing needed." >> "${stdout_log}"
#     input_file="$original_input_file"
# fi

# Run animal_warper directly with the deobliqued file
animal_warper_cmd="@animal_warper -input \"$input_file\" -feature_size 0.4-base \"$base_file\" -outdir \"$output_dir\" -skullstrip \"$skullstrip_file\" -cost nmi -ok_to_exist"

# Debug: Print the constructed command
echo "Running @animal_warper with the following command:" >> "${stdout_log}"
echo "$animal_warper_cmd" >> "${stdout_log}"

# Run the command using eval
eval "$animal_warper_cmd" >> "${stdout_log}" 2>> "${stderr_log}"
