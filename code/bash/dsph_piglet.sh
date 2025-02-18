#!/bin/bash

# Show usage if no input file is provided
if [ "$#" -lt 1 ]; then
    echo "Usage: $0 <input_file> [orient_mid] [I_pad] [P_pad] [R_pad] [L_pad]"
    echo "Default values:"
    echo "  orient_mid: RSP"
    echo "  I_pad: 80"
    echo "  P_pad: 30"
    echo "  R_pad: 30"
    echo "  L_pad: 25"
    echo "Example: $0 input.nii.gz"
    exit 1
fi

# Assign arguments with defaults
input_file="$1"
orient_mid="${2:-RSP}"  # Default: RSP
I_pad="${3:-80}"        # Default: 80
P_pad="${4:-30}"        # Default: 30
R_pad="${5:-30}"        # Default: 30
L_pad="${6:-25}"        # Default: 25

# Generate prefix file name automatically from input file
prefix_file="${input_file%.nii.gz}_DSPH_${orient_mid}.nii.gz"

# Check if desphinxify exists
if ! command -v desphinxify &> /dev/null; then
    echo "Error: desphinxify command not found"
    exit 1
fi

# Construct and execute desphinxify command
dsph_cmd="desphinxify -orient_mid ${orient_mid} -input \"${input_file}\" -prefix \"${prefix_file}\" -overwrite"
eval "$dsph_cmd"

# Generate output file name for padding
output_file="${prefix_file%.nii.gz}_pad.nii.gz"

# Construct and execute padding command
pad_cmd="3dZeropad -I -${I_pad} -P -${P_pad} -R -${R_pad} -L -${L_pad} -prefix \"${output_file}\" \"${prefix_file}\""
eval "$pad_cmd"


# the order does not matter, but the padding direction would be different
