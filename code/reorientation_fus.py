import os
import sys
import nibabel as nib
import numpy as np

def fix_orientation(input_file, output_file):
    img = nib.load(input_file)

    data = img.get_fdata()
    affine = img.affine
    
    matrix = np.array([[-1, 0, 0, 0],
                           [0, 1, 0, 0],
                           [0, 0, 1, 0],
                           [0, 0, 0, 1]])
    
    transformed_affine = matrix @ affine
    
    # Flip the z-axis on fUS data, which has wrong orientation on z-axis
    reoriented_data = np.flip(data, axis=2)
    
    new_img = nib.Nifti1Image(reoriented_data, transformed_affine, img.header)
    nib.save(new_img, output_file)
    
    print(f"Adjusted affine fUS image saved to {output_file}")

def main():
    if len(sys.argv) != 2:
        print("Usage: python script.py input_file")
        sys.exit(1)
    
    input_file = sys.argv[1]
    
    # Check the file extension
    valid_extensions = ['.nii', '.nii.gz']
    if not any(input_file.endswith(ext) for ext in valid_extensions):
        print("Error: Input file must have a .nii or .nii.gz extension")
        sys.exit(1)
    
    # Get the directory and base name of the input file
    input_dir = os.path.dirname(input_file)
    input_basename = os.path.basename(input_file)
    
    # Create the output file name
    if input_basename.endswith('.nii.gz'):
        output_basename = input_basename.replace('.nii.gz', '_corrected.nii.gz')
    else:
        output_basename = input_basename.replace('.nii', '_corrected.nii.gz')
    
    output_file = os.path.join(input_dir, output_basename)
    
    # Fix the orientation
    fix_orientation(input_file, output_file)

if __name__ == "__main__":
    main()