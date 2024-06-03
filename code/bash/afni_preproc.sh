#!/bin/bash

# Usage function
usage() {
    echo "Usage: $0 -i input_file -b base_file -a atlas_file -s skullstrip_file -o output_dir -r reoriented_output_dir"
    exit 1
}

# Parse command-line arguments
while getopts "i:b:a:s:o:r:" opt; do
    case $opt in
        i) original_input_file="$OPTARG" ;;
        b) base_file="$OPTARG" ;;
        a) atlas_file="$OPTARG" ;;
        s) skullstrip_file="$OPTARG" ;;
        o) output_dir="$OPTARG" ;;
        r) reoriented_output_dir="$OPTARG" ;;
        *) usage ;;
    esac
done

# Check if all arguments are provided
if [ -z "$original_input_file" ] || [ -z "$base_file" ] || [ -z "$atlas_file" ] || [ -z "$skullstrip_file" ] || [ -z "$output_dir" ] || [ -z "$reoriented_output_dir" ]; then
    usage
fi

# Create output directories
mkdir -p "${output_dir}"
mkdir -p "${reoriented_output_dir}"

# Log files
stdout_log="${output_dir}/output.log"
stderr_log="${output_dir}/error.log"

# Check orientations
input_orientation=$(3dinfo -orient "$original_input_file")
base_orientation=$(3dinfo -orient "$base_file")
input_obliquity=$(3dinfo -obliquity "$original_input_file")

echo "Input file orientation: $input_orientation" >> "${stdout_log}"
echo "Base file orientation: $base_orientation" >> "${stdout_log}"
echo "Input file obliquity: $input_obliquity" >> "${stdout_log}"

# Reorient if necessary
if [ "$input_obliquity" != "0.000" ]; then
    echo "Input file is oblique. Reorienting to cardinal orientation." >> "${stdout_log}"
    
    # Deoblique
    temp_prefix=fusi_raw_deo
    3dWarp -oblique2card -prefix "${reoriented_output_dir}/${temp_prefix}.nii.gz" "${original_input_file}" >> "${stdout_log}" 2>> "${stderr_log}"
    
    # Use the reoriented file
    input_file="${reoriented_output_dir}/${temp_prefix}.nii.gz"
else
    echo "Input file is already in cardinal orientation. No reorientation needed." >> "${stdout_log}"
    input_file="$original_input_file"
fi

# Determine if any flips are needed based on orientation comparison
flip_needed=false

# Function to determine if a specific flip is needed
check_and_flip() {
    local axis=$1
    local input_orientation_code=$2
    local base_orientation_code=$3
    local flip_command=$4

    if [ "$input_orientation_code" != "$base_orientation_code" ]; then
        echo "Orientation mismatch on $axis axis. Applying flip." >> "${stdout_log}"
        flip_needed=true
        temp_input="${temp_prefix}"
        temp_prefix="${temp_prefix}_flip_${axis}"
        $flip_command -prefix "${reoriented_output_dir}/${temp_prefix}.nii.gz" "${reoriented_output_dir}/${temp_input}.nii.gz" >> "${stdout_log}" 2>> "${stderr_log}"
        input_file="${reoriented_output_dir}/${temp_prefix}.nii.gz"
    fi
}

temp_prefix=$(basename "$input_file" .nii.gz)

# Check and apply flips if needed
check_and_flip "Y" "${input_orientation:1:1}" "${base_orientation:1:1}" "3dLRflip -Y"
check_and_flip "Z" "${input_orientation:2:1}" "${base_orientation:2:1}" "3dLRflip -Z"  # 3dSIflip is not a valid AFNI command, use -Z for Z-axis flip
check_and_flip "X" "${input_orientation:0:1}" "${base_orientation:0:1}" "3dLRflip -X"  # 3dAPflip is not a valid AFNI command, use -X for X-axis flip

# Final re-orientation to match template using 3drefit
if [ "$flip_needed" = true ]; then
    echo "Applying 3drefit to correct orientation in header to match the base file." >> "${stdout_log}"
    temp_input="${temp_prefix}"
    temp_prefix="${temp_prefix}_rf"
    3drefit -orient "$base_orientation" "${reoriented_output_dir}/${temp_input}.nii.gz" >> "${stdout_log}" 2>> "${stderr_log}"
    input_file="${reoriented_output_dir}/${temp_prefix}.nii.gz"
fi

# Ensure the voxel grid matches the desired orientation using 3dresample
echo "Applying 3dresample to reorient and resample the voxel grid to match the base file." >> "${stdout_log}"
temp_input="${temp_prefix}"
temp_prefix="${temp_prefix}_rs"
3dresample -orient "$base_orientation" -prefix "${reoriented_output_dir}/${temp_prefix}.nii.gz" -input "${reoriented_output_dir}/${temp_input}.nii.gz" >> "${stdout_log}" 2>> "${stderr_log}"

input_file="${reoriented_output_dir}/${temp_prefix}.nii.gz"

# Log the files being used
echo "Final input file: $input_file" >> "${stdout_log}"
echo "Base file: $base_file" >> "${stdout_log}"
echo "Atlas file: $atlas_file" >> "${stdout_log}"
echo "Skullstrip file: $skullstrip_file" >> "${stdout_log}"
echo "Output directory: $output_dir" >> "${stdout_log}"

# Run the animal_warper command with the atlas option
echo "Running @animal_warper at $(date)" >> "${stdout_log}"
@animal_warper -input "$input_file" -base "$base_file" -atlas "$atlas_file" -outdir "$output_dir" -skullstrip "$skullstrip_file" -ok_to_exist >> "${stdout_log}" 2>> "${stderr_log}"

# Log the end of the script
echo "Script finished at $(date)" >> "${stdout_log}"
