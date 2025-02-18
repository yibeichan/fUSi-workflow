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

# Set default cost function
cost_function="lpa"

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -i|--input)
            input_file="$2"
            shift 2
            ;;
        -c|--cost)
            cost_function="$2"
            shift 2
            ;;
        *)
            echo "Unknown parameter: $1"
            echo "Usage: $0 -i <input_file> [-c <cost_function>]"
            exit 1
            ;;
    esac
done

# Validate required arguments
if [ -z "$input_file" ]; then
    echo "Error: Input file is required"
    echo "Usage: $0 -i <input_file> [-c <cost_function>]"
    exit 1
fi

# Set output directory to be in same parent directory as input file
output_dir="$(dirname "$input_file")/aw_results3"

# Fixed paths for base and skullstrip files
base_file="/Users/yibeichen/Desktop/fusi/atlas/template_T1w.nii.gz"
skullstrip_file="/Users/yibeichen/Desktop/fusi/atlas/mask_brain.nii.gz"

# Create output directory if it doesn't exist
mkdir -p "$output_dir"

# Define log files
stdout_log="${output_dir}/animal_warper_stdout.log"
stderr_log="${output_dir}/animal_warper_stderr.log"

original_input_file="$input_file"

animal_warper_cmd="@animal_warper -input \"$input_file\" -base \"$base_file\" -outdir \"$output_dir\" -skullstrip \"$skullstrip_file\" -cost {} -ok_to_exist"

# Debug: Print the constructed command
echo "Running @animal_warper with the following command:" >> "${stdout_log}"
echo "$animal_warper_cmd" >> "${stdout_log}"

# Run the command using eval
eval "$animal_warper_cmd" >> "${stdout_log}" 2>> "${stderr_log}"