#!/bin/bash

# Paths to preprocessed images
FUS_PATH="/Users/yibeichen/Documents/GitHub/fUSi-workflow/data/0527/fusi_corrected_preprocessed.nii.gz"
MRA_PATH="/Users/yibeichen/Documents/GitHub/fUSi-workflow/data/0527/angio_preprocessed.nii.gz"
OUTPUT_PREFIX="/Users/yibeichen/Documents/GitHub/fUSi-workflow/data/0527/fusi_flirt_bbr_6"

# Perform rigid registration using FLIRT with bbr cost function
flirt -in $FUS_PATH -ref $MRA_PATH -out ${OUTPUT_PREFIX}.nii.gz -omat ${OUTPUT_PREFIX}.mat -cost bbr -searchrx -30 30 -searchry -30 30 -searchrz -30 30 -dof 6 -schedule $FSLDIR/etc/flirtsch/bbr.sch

echo "Rigid registration with bbr saved to ${OUTPUT_PREFIX}.nii.gz"
