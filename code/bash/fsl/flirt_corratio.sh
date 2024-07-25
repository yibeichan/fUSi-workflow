#!/bin/bash

# Paths to preprocessed images
FUS_PATH="/Users/yibeichen/Documents/GitHub/fUSi-workflow/data/0527/fusi_corrected_preprocessed.nii.gz"
MRA_PATH="/Users/yibeichen/Documents/GitHub/fUSi-workflow/data/0527/angio_preprocessed.nii.gz"
OUTPUT_PREFIX="/Users/yibeichen/Documents/GitHub/fUSi-workflow/data/0527/fusi_flirt_corratio_6"

# Perform rigid registration using FLIRT
flirt -in $FUS_PATH -ref $MRA_PATH -out ${OUTPUT_PREFIX}.nii.gz -omat ${OUTPUT_PREFIX}.mat -cost corratio -dof 6

echo "Rigid registration saved to ${OUTPUT_PREFIX}.nii.gz"
