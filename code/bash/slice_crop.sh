#!/bin/bash

filename="anat_raw.deo.ryf.rf.rs" # remove nii.gz
z_cut_sup=4.5            # mm (+)
z_cut_inf=-19.5          # mm (-)
y_cut_post=18.5          # mm (+)
y_cut_ant=-28            # mm (-)
x_cut_cor_left=21.5      # mm (+)
x_cut_cor_right=-14      # mm (-)

#################################### Main #######################################################
cd ./anat # needs to be changed 
re_int='^[+-]?[0-9]+([.][0-9]+)?$' # regular expression to test for a signaled integer
# Delete file if it exists
rm -rf ${filename}.cropped.nii.gz

# Get the dimensions of the brick
dims=(`3dinfo -extent ${filename}.nii.gz`) # Right Left Ant Post Inf Sup
zsup=${dims[5]}
zinf=${dims[4]}
ypost=${dims[3]}
yant=${dims[2]}
xleft=${dims[1]}
xright=${dims[0]}
z_cut_sup_temp="${z_cut_sup}"
z_cut_inf_temp="${z_cut_inf}"
y_cut_post_temp="${y_cut_post}"
y_cut_ant_temp="${y_cut_ant}"
x_cut_cor_left_temp="${x_cut_cor_left}"
x_cut_cor_right_temp="${x_cut_cor_right}"

# If the value to cut is not an integer, make it the dim of the brick
if [[ ! "${z_cut_sup}" =~ ${re_int} ]]; then # Don't double quote ${re_int}!
    z_cut_sup_temp="${zsup}"
fi
if [[ ! "${z_cut_inf}" =~ ${re_int} ]]; then
    z_cut_inf_temp="${zinf}"
fi
if [[ ! "${y_cut_post}" =~ ${re_int} ]]; then
    y_cut_post_temp="${ypost}"
fi
if [[ ! "${y_cut_ant}" =~ ${re_int} ]]; then
    y_cut_ant_temp="${yant}"
fi
if [[ ! "${x_cut_cor_left}" =~ ${re_int} ]]; then
    x_cut_cor_left_temp="${xleft}"
fi
if [[ ! "${x_cut_cor_right}" =~ ${re_int} ]]; then
    x_cut_cor_right_temp="${xright}"
fi

mm_cut_from_zsup=`awk "BEGIN{ print ${z_cut_sup_temp} - ${zsup} }"` # Bash doesn't support floats so we use awk
mm_cut_from_zinf=`awk "BEGIN{ print ${zinf} - ${z_cut_inf_temp} }"`
mm_cut_from_ypost=`awk "BEGIN{ print ${y_cut_post_temp} - ${ypost} }"`
mm_cut_from_yant=`awk "BEGIN{ print ${yant} - ${y_cut_ant_temp} }"`
mm_cut_from_xleft=`awk "BEGIN{ print ${x_cut_cor_left_temp} - ${xleft} }"`
mm_cut_from_xright=`awk "BEGIN{ print ${xright} - ${x_cut_cor_right_temp} }"`

echo ''
echo ANAT
echo mm_cut_from_zsup = "${mm_cut_from_zsup}"
echo mm_cut_from_zinf = "${mm_cut_from_zinf}"
echo mm_cut_from_ypost = "${mm_cut_from_ypost}"
echo mm_cut_from_yant = "${mm_cut_from_yant}"
echo mm_cut_from_xleft = "${mm_cut_from_xleft}"
echo mm_cut_from_xright = "${mm_cut_from_xright}"

3dZeropad -mm -S "${mm_cut_from_zsup}" -I "${mm_cut_from_zinf}" \
   -P "${mm_cut_from_ypost}" -A "${mm_cut_from_yant}"           \
   -L "${mm_cut_from_xleft}" -R "${mm_cut_from_xright}"         \
   -prefix ${filename}.cropped.nii.gz               \
   ${filename}.nii.gz