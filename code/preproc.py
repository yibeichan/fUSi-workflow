import os
import ants


base_dir = os.path.dirname(os.getcwd())
data_dir = os.path.join(base_dir, "data")
output_dir = os.path.join(base_dir, "output")

# co-register two T1w images

img_path1 = os.path.join(output_dir, 'Florian_MRI_nifti', 'T1w_MPR_20240405094408.nii.gz')
img_path2 = os.path.join(output_dir, 'Florian_MRI_nifti', 'T1w_MPR_20240405094408a.nii.gz')

# Load the images
fixed_image = ants.image_read(img_path1)
moving_image = ants.image_read(img_path2)

# Run the registration (this is a simplified example; see ANTsPy documentation for all options)
registration = ants.registration(fixed=fixed_image, moving=moving_image, type_of_transform='SyN')

# Apply the transformation to the moving image
moving_transformed = ants.apply_transforms(fixed=fixed_image, moving=moving_image, transformlist=registration['fwdtransforms'])

# Average the fixed image and the transformed moving image
average_image_data = (fixed_image.numpy() + moving_transformed.numpy()) / 2.0
average_image = ants.from_numpy(average_image_data, origin=fixed_image.origin, spacing=fixed_image.spacing, direction=fixed_image.direction)

save_dir = os.path.join(output_dir, 'Florian_preproc')
ants.image_write(average_image, os.path.join(save_dir, 'T1w_MPR_averaged.nii.gz'))
