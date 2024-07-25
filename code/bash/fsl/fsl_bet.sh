#!/bin/bash

# Path to input fUS image
FUS_PATH="/Users/yibeichen/Documents/GitHub/fUSi-workflow/data/052702/fusi_corrected.nii.gz"

# Path to output skull-stripped fUS image
OUTPUT_FUS_PATH="/Users/yibeichen/Documents/GitHub/fUSi-workflow/data/052702/fusi_corrected_bet.nii.gz"

# Path to output initial brain mask
INITIAL_MASK="/Users/yibeichen/Documents/GitHub/fUSi-workflow/data/052702/fusi_corrected_bet_mask.nii.gz"

# Run BET with a fractional intensity threshold to create an initial mask
bet $FUS_PATH $OUTPUT_FUS_PATH -f 0.8 -g 0 -m

# The '-m' option outputs a binary brain mask with a '_mask' suffix
mv ${OUTPUT_FUS_PATH}_mask.nii.gz $INITIAL_MASK

echo "Initial skull-stripped fUS image saved to $OUTPUT_FUS_PATH"
echo "Initial brain mask saved to $INITIAL_MASK"
