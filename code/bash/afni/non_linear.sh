#!/bin/bash

# Paths to preprocessed images
FUS_PATH="/Users/yibeichen/Documents/GitHub/fUSi-workflow/data/0527/fusi_corrected_preprocessed.nii.gz"
MRA_PATH="/Users/yibeichen/Documents/GitHub/fUSi-workflow/data/0527/angio_preprocessed.nii.gz"
OUTPUT_PREFIX="/Users/yibeichen/Documents/GitHub/fUSi-workflow/data/0527/fusi_afni_non_linear"
AFFINE_MATRIX="/Users/yibeichen/Documents/GitHub/fUSi-workflow/data/0527/fusi_afni_non_linear_affine.aff12.1D"

# Perform initial affine registration using 3dAllineate
3dAllineate -base $MRA_PATH -input $FUS_PATH -prefix ${OUTPUT_PREFIX}_affine.nii.gz -1Dmatrix_save $AFFINE_MATRIX -cost lpc -cmass -autoweight -twopass -final wsinc5

# Perform non-linear registration using 3dQwarp
3dQwarp -base $MRA_PATH -source ${OUTPUT_PREFIX}_affine.nii.gz -prefix ${OUTPUT_PREFIX}.nii.gz -duplo -iwarp -useweight

echo "Non-linear registration saved to ${OUTPUT_PREFIX}.nii.gz"
