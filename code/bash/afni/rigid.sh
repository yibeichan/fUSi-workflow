#!/bin/bash

# Paths to preprocessed images
FUS_PATH="/Users/yibeichen/Documents/GitHub/fUSi-workflow/data/0527/fusi_corrected_preprocessed.nii.gz"
MRA_PATH="/Users/yibeichen/Documents/GitHub/fUSi-workflow/data/0527/angio_preprocessed.nii.gz"
OUTPUT_PREFIX="/Users/yibeichen/Documents/GitHub/fUSi-workflow/data/0527/fusi_afni_rigid"

# Perform rigid registration using 3dvolreg
3dvolreg -base $MRA_PATH -input $FUS_PATH -prefix ${OUTPUT_PREFIX}.nii.gz -1Dmatrix_save ${OUTPUT_PREFIX}.aff12.1D -cost lpc

echo "Rigid registration saved to ${OUTPUT_PREFIX}.nii.gz"