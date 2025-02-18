original_input_file="/Users/yibeichen/Desktop/fusi/raw_data/Atsushi_FengLab_Unna_exvivo_11_1_1.nii"
base_file="/Users/yibeichen/Desktop/fusi/atlas/template_T1w.nii.gz"
atlas_file1="/Users/yibeichen/Desktop/fusi/atlas/atlas_MBM_cortex_vH.nii.gz"
atlas_file2="/Users/yibeichen/Desktop/fusi/atlas/atlas_MBM_subcortical_beta.nii.gz"
skullstrip_file="/Users/yibeichen/Desktop/fusi/atlas/mask_brain.nii.gz"
output_dir="/Users/yibeichen/Desktop/fusi/aw_results_mri_unna"
reoriented_output_dir="/Users/yibeichen/Desktop/fusi/reorient_unna"

# Add checks to verify files/directories exist
if [ ! -f "$original_input_file" ]; then
    echo "Error: Input file not found: $original_input_file"
    exit 1
fi

if [ ! -f "$base_file" ]; then
    echo "Error: Base file not found: $base_file"
    exit 1
fi

# Create a new tmux session named 'afni_proc'
tmux new-session -d -s afni_proc

# Send the commands to the tmux session
tmux send-keys -t afni_proc "bash /Users/yibeichen/Documents/GitHub/fUSi-workflow/code/bash/afni_preproc.sh -i \"$original_input_file\" -b \"$base_file\" -a \"$atlas_file1\" \"$atlas_file2\" -s \"$skullstrip_file\" -o \"$output_dir\" -r \"$reoriented_output_dir\"" C-m

# Attach to the tmux session
tmux attach-session -t afni_proc
