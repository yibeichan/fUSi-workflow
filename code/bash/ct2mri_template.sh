# 2
# input_file="/Users/yibeichen/Desktop/fusi/microCT/wolfgang/MASK_Marmoset1_skull_200micron_recenter_resize.nii.gz"
# base_file="/Users/yibeichen/Desktop/fusi/atlas/template_T1w_inverted.nii.gz"
# output_dir="/Users/yibeichen/Desktop/fusi/microCT/wolfgang/aw_results2"
# skullstrip_file="/Users/yibeichen/Desktop/fusi/atlas/mask_brain.nii.gz"

# @animal_warper -input $input_file -base $base_file -outdir $output_dir -skullstrip $skullstrip_file -cost lpc+zz  -ok_to_exist

# #3
# input_file="/Users/yibeichen/Desktop/fusi/microCT/wolfgang/MASK_Marmosete_brain_B_200micron_reoriented_resampled.nii.gz"
# base_file="/Users/yibeichen/Desktop/fusi/atlas/template_T2w_brain.nii.gz"
# output_dir="/Users/yibeichen/Desktop/fusi/microCT/wolfgang/aw_results3"

# @animal_warper -input $input_file -base $base_file -outdir $output_dir -cost nmi  -ok_to_exist

#4
# input_file="/Users/yibeichen/Desktop/fusi/microCT/wolfgang/MASK_Marmosete_brain_B_200micron_reoriented_resampled.nii.gz"
# base_file="/Users/yibeichen/Desktop/fusi/atlas/template_T2w_brain.nii.gz"
# output_dir="/Users/yibeichen/Desktop/fusi/microCT/wolfgang/aw_results4"

# @animal_warper -input $input_file -base $base_file -outdir $output_dir -cost lpc+zz  -ok_to_exist

#5 sucessful at the first try, now try with atlas
atlas_dir="/Users/yibeichen/Desktop/fusi/atlas/"
input_file="/Users/yibeichen/Desktop/fusi/microCT/wolfgang/MASK_Marmosete_brain_B_200micron_reoriented_resampled.nii.gz"
base_file="/Users/yibeichen/Desktop/fusi/atlas/template_T1w_brain.nii.gz"
atlas_file1="${atlas_dir}/atlas_MBM_cortex_vH.nii.gz"
atlas_file2="${atlas_dir}/aw_SAM_to_MBM_brainstem_fs0.8_1/SAMv1_atlas_warp2std.nii.gz"
output_dir="/Users/yibeichen/Desktop/fusi/microCT/wolfgang/aw_results5"
zeropad_atlas_file2_prefix="${atlas_dir}/SAMv1_atlas_warp2std_padded"

3dZeropad -master $atlas_file1 -prefix $zeropad_atlas_file2_prefix $atlas_file2
3dAFNItoNIFTI -prefix $zeropad_atlas_file2_prefix.nii.gz $zeropad_atlas_file2_prefix+tlrc
# writ
@animal_warper -input $input_file -base $base_file -outdir $output_dir -atlas $atlas_file1 $zeropad_atlas_file2_prefix.nii.gz -cost lpc+zz  -ok_to_exist

#6 failed due to different grid size
# input_file="/Users/yibeichen/Desktop/fusi/microCT/wolfgang/MASK_Marmosete_brain_B_200micron_reoriented_resize015.nii.gz"
# atlas_file1="/Users/yibeichen/Desktop/fusi/atlas/atlas_MBM_cortex_vH.nii.gz"
# atlas_file2="/Users/yibeichen/Desktop/fusi/atlas/SAMv1.0.nii.gz"
# base_file="/Users/yibeichen/Desktop/fusi/atlas/SAM_T2_template.nii.gz"
# output_dir="/Users/yibeichen/Desktop/fusi/microCT/wolfgang/aw_results6"
# mask_file="/Users/yibeichen/Desktop/fusi/atlas/mask_brain.nii.gz"

# @animal_warper -input $input_file -base $base_file -outdir $output_dir -atlas $atlas_file1 $atlas_file2 -cost lpc+zz  -ok_to_exist

#7 with skull-on template, not good
# input_file="/Users/yibeichen/Desktop/fusi/microCT/wolfgang/MASK_Marmosete_brain_B_200micron_reoriented_resize015.nii.gz"
# atlas_file1="/Users/yibeichen/Desktop/fusi/atlas/atlas_MBM_cortex_vH.nii.gz"
# atlas_file2="/Users/yibeichen/Desktop/fusi/atlas/aw_SAM_to_MBM_brainstem_fs0.8_1/SAMv1_atlas_warp2std.nii.gz"
# base_file="/Users/yibeichen/Desktop/fusi/atlas/template_T1w.nii.gz"
# output_dir="/Users/yibeichen/Desktop/fusi/microCT/wolfgang/aw_results7"
# mask_file="/Users/yibeichen/Desktop/fusi/atlas/mask_brain.nii.gz"

# @animal_warper -input $input_file -base $base_file -outdir $output_dir -atlas $atlas_file1 $atlas_file2 -skullstrip $mask_file -cost lpc+zz  -ok_to_exist

#8 so weidly misaligned
# input_file="/Users/yibeichen/Desktop/fusi/microCT/wolfgang/MASK_Marmosete_brain_B_200micron_reoriented_resize015.nii.gz"
# atlas_file1="/Users/yibeichen/Desktop/fusi/atlas/atlas_MBM_cortex_vH.nii.gz"
# atlas_file2="/Users/yibeichen/Desktop/fusi/atlas/aw_SAM_to_MBM_brainstem_fs0.8_1/SAMv1_atlas_warp2std.nii.gz"
# base_file="/Users/yibeichen/Desktop/fusi/atlas/template_T1w_brain.nii.gz"
# output_dir="/Users/yibeichen/Desktop/fusi/microCT/wolfgang/aw_results8"
# # mask_file="/Users/yibeichen/Desktop/fusi/atlas/mask_brain.nii.gz"

# @animal_warper -input $input_file -base $base_file -outdir $output_dir -atlas $atlas_file1 $atlas_file2 -cost lpc+zz  -ok_to_exist