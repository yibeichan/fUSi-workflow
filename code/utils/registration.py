import numpy as np
import nibabel as nib
from nibabel.orientations import aff2axcodes

def nifit_info(file):
    img = nib.load(file)
    data = img.get_fdata()

    return data.shape, img.affine, aff2axcodes(img.affine)

def get_transform_matrix(file1, file2): 
    affine1 = nib.load(file1).affine
    affine2 = nib.load(file2).affine

    return affine2 @ np.linalg.inv(affine1)

def correct4registration(infile, outfile):
    img = nib.load(infile)
    data = img.get_fdata()
    affine = img.affine

    corrected_affine = affine.copy()
    corrected_affine[[0, 1]] = corrected_affine[[1, 0]]

    print("Corrected Affine:\n", corrected_affine)
    print(aff2axcodes(corrected_affine))
    # reflect z to be positive
    transform_matrix = np.array([[1, 0, 0, 0],
                                [0, 1, 0, 0],
                                [0, 0, -1, 0],
                                [0, 0, 0, 1]])

    transformed_affine = corrected_affine @ transform_matrix

    print(transformed_affine)

    # Create a new affine matrix for RAS orientation
    ras_affine = np.zeros_like(transformed_affine)

    # Copy the necessary elements to match RAS
    ras_affine[0, :] = transformed_affine[1, :]
    ras_affine[1, :] = transformed_affine[0, :]
    ras_affine[2, :] = transformed_affine[2, :]

    # The last row should remain the same (for homogeneous coordinates)
    ras_affine[3, :] = transformed_affine[3, :]

    print("RAS Affine:\n", ras_affine)

    # flip A/P (data was wrong) and S/I(match transformed affine)
    flipped_data = np.flip(np.flip(data, axis=0), axis=2)

    new_img = nib.Nifti1Image(flipped_data, transformed_affine, img.header)
    print(new_img.affine, aff2axcodes(new_img.affine))

    nib.save(new_img, outfile)

    return new_img