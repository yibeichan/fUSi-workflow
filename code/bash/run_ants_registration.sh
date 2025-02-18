#!/bin/bash

# Define your input file paths and output prefix
TEMPLATE_MRI="/Users/yibeichen/Desktop/fusi/atlas/template_T1w_brain.nii.gz"  # Path to your MRI template
MOVING_CT="/Users/yibeichen/Desktop/fusi/microCT/MASK_Marmosete_brain_B_200micron.nii.gz"  # Path to your CT scan
OUTPUT_PREFIX="aligned_"  # Prefix for the output files
LOG_FILE="/Users/yibeichen/Documents/GitHub/fUSi-workflow/logs/registration_log.txt"  # Log file to store output

# antsRegistration command for rigid and affine alignment
antsRegistration --dimensionality 3 \
  --float 0 \
  --output [${OUTPUT_PREFIX}, ${OUTPUT_PREFIX}Warped.nii.gz, ${OUTPUT_PREFIX}InverseWarped.nii.gz] \
  --interpolation Linear \
  --initial-moving-transform [${TEMPLATE_MRI}, ${MOVING_CT}, 1] \
  --transform Rigid[0.1] \
  --metric MI[${TEMPLATE_MRI}, ${MOVING_CT}, 1, 32, Regular, 0.25] \
  --convergence [1000x500x250x100, 1e-6, 10] \
  --shrink-factors 8x4x2x1 \
  --smoothing-sigmas 3x2x1x0vox \
  --transform Affine[0.1] \
  --metric MI[${TEMPLATE_MRI}, ${MOVING_CT}, 1, 32, Regular, 0.25] \
  --convergence [1000x500x250x100, 1e-6, 10] \
  --shrink-factors 8x4x2x1 \
  --smoothing-sigmas 3x2x1x0vox \
  &> ${LOG_FILE}

# Check if the command was successful and log the status
if [ $? -eq 0 ]; then
    echo "Registration completed successfully!" | tee -a ${LOG_FILE}
else
    echo "Registration failed. Check the log file for details." | tee -a ${LOG_FILE}
fi
