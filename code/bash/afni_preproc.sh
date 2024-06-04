#!/bin/bash

# Usage function
usage() {
    echo "Usage: $0 -i input_file -b base_file -a atlas_file1 atlas_file2 -s skullstrip_file -o output_dir -r reoriented_output_dir"
    exit 1
}

# Function to strip .nii or .nii.gz extension
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

# Initialize variables
atlas_files=()
original_input_file=""
base_file=""
skullstrip_file=""
output_dir=""
reoriented_output_dir=""

# Parse command-line arguments
while getopts "i:b:a:s:o:r:" opt; do
    case $opt in
        i) original_input_file="$OPTARG" ;;
        b) base_file="$OPTARG" ;;
        a) atlas_files+=("$OPTARG") ;; # Capture the initial -a argument
        s) skullstrip_file="$OPTARG" ;;
        o) output_dir="$OPTARG" ;;
        r) reoriented_output_dir="$OPTARG" ;;
        *) usage ;;
    esac
done

# Shift away the parsed options
shift $((OPTIND - 1))

# Capture any remaining arguments as atlas files, ensuring the -s, -o, and -r options are not included
while [ $# -gt 0 ]; do
    case $1 in
        -s) skullstrip_file="$2"; shift 2 ;;
        -o) output_dir="$2"; shift 2 ;;
        -r) reoriented_output_dir="$2"; shift 2 ;;
        *) atlas_files+=("$1"); shift ;;
    esac
done

# Debugging statements to see parsed options
echo "Debug: Parsed options"
echo "original_input_file: $original_input_file"
echo "base_file: $base_file"
echo "atlas_files (initial): ${atlas_files[@]}"
echo "skullstrip_file: $skullstrip_file"
echo "output_dir: $output_dir"
echo "reoriented_output_dir: $reoriented_output_dir"

# Shift away the parsed options
shift $((OPTIND - 1))

# Capture any remaining arguments as atlas files
for arg in "$@"; do
    atlas_files+=("$arg")
done

# Debugging statement to see all atlas files
echo "Debug: Atlas files after capturing remaining arguments: ${atlas_files[@]}"

# Check if all arguments are provided
if [ -z "$original_input_file" ]; then
    echo "Debug: Missing original_input_file"
fi
if [ -z "$base_file" ]; then
    echo "Debug: Missing base_file"
fi
if [ ${#atlas_files[@]} -lt 2 ]; then
    echo "Debug: Less than two atlas files provided"
fi
if [ -z "$skullstrip_file" ]; then
    echo "Debug: Missing skullstrip_file"
fi
if [ -z "$output_dir" ]; then
    echo "Debug: Missing output_dir"
fi
if [ -z "$reoriented_output_dir" ]; then
    echo "Debug: Missing reoriented_output_dir"
fi

if [ -z "$original_input_file" ] || [ -z "$base_file" ] || [ ${#atlas_files[@]} -lt 2 ] || [ -z "$skullstrip_file" ] || [ -z "$output_dir" ] || [ -z "$reoriented_output_dir" ]; then
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
    
    base_filename=$(strip_extension "$original_input_file")
    temp_prefix="${base_filename}_deo"
    echo "Temp prefix: $temp_prefix" >> "${stdout_log}"
    3dWarp -oblique2card -prefix "${reoriented_output_dir}/${temp_prefix}.nii.gz" "${original_input_file}" >> "${stdout_log}" 2>> "${stderr_log}"
    
    # Use the reoriented file
    input_file="${reoriented_output_dir}/${temp_prefix}.nii.gz"
else
    echo "Input file is already in cardinal orientation. No reorientation needed." >> "${stdout_log}"
    input_file="$original_input_file"
    base_filename=$(strip_extension "$input_file")
    temp_prefix="${base_filename}"
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

    # Copy the file to ensure original is not overwritten
    rm -f "${reoriented_output_dir}/${temp_prefix}.nii.gz"
    3dcopy "${reoriented_output_dir}/${temp_input}.nii.gz" "${reoriented_output_dir}/${temp_prefix}.nii.gz" >> "${stdout_log}" 2>> "${stderr_log}"

    # Ensure the file exists after 3dcopy
    if [ ! -f "${reoriented_output_dir}/${temp_prefix}.nii.gz" ]; then
        echo "Error: Copied file not found: ${reoriented_output_dir}/${temp_prefix}.nii.gz" >> "${stderr_log}"
        exit 1
    fi
    
    # Apply 3drefit
    3drefit -orient "$base_orientation" "${reoriented_output_dir}/${temp_prefix}.nii.gz" >> "${stdout_log}" 2>> "${stderr_log}"
    
    # Ensure the file exists after 3drefit
    if [ ! -f "${reoriented_output_dir}/${temp_prefix}.nii.gz" ]; then
        echo "Error: Refitted file not found: ${reoriented_output_dir}/${temp_prefix}.nii.gz" >> "${stderr_log}"
        exit 1
    fi

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
for file in "${atlas_files[@]}"; do
  echo "Atlas file: $file" >> "${stdout_log}"
done
echo "Skullstrip file: $skullstrip_file" >> "${stdout_log}"
echo "Output directory: $output_dir" >> "${stdout_log}"

# Run the animal_warper command with the atlas option
echo "Running @animal_warper at $(date)" >> "${stdout_log}"
# Construct the @animal_warper command as a string
animal_warper_cmd="@animal_warper -input \"$input_file\" -base \"$base_file\" -atlas"

# Concatenate all atlas files
for atlas in "${atlas_files[@]}"; do
    animal_warper_cmd="$animal_warper_cmd \"$atlas\""
done

# Add the remaining options
animal_warper_cmd="$animal_warper_cmd -outdir \"$output_dir\" -skullstrip \"$skullstrip_file\" -ok_to_exist"

# Debug: Print the constructed command
echo "Running @animal_warper with the following command:" >> "${stdout_log}"
echo "$animal_warper_cmd" >> "${stdout_log}"

# Run the command using eval
eval "$animal_warper_cmd" >> "${stdout_log}" 2>> "${stderr_log}"

# Check if @animal_warper succeeded
if [ $? -ne 0 ]; then
    echo "Error: @animal_warper command failed. Check ${stderr_log} for details." >> "${stderr_log}"
    exit 1
fi

echo "Script finished at $(date)" >> "${stdout_log}"
