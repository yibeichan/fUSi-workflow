import os
from dotenv import load_dotenv
import h5py
import numpy as np
from tqdm import tqdm
from joblib import Parallel, delayed
from tqdm_joblib import tqdm_joblib
import SimpleITK as sitk


def validate_files(*file_paths):
    """
    Validate if all given files exist. Raise an error if any are not found.
    """
    for file_path, description in file_paths:
        if not os.path.exists(file_path):
            raise FileNotFoundError(f"{description} file not found at: {file_path}")


def load_transform_matrix(transform_mtx_file):
    """
    Load the transformation matrix from an h5 file.
    """
    with h5py.File(transform_mtx_file, 'r') as f:
        transform_parameters = np.array(f['TransformGroup/0/TransformParameters'])
        fixed_parameters = np.array(f['TransformGroup/0/TransformFixedParameters'])

    affine_transform = sitk.AffineTransform(3)
    affine_transform.SetMatrix(transform_parameters[:9])  # First 9 are rotation/scaling
    affine_transform.SetTranslation(transform_parameters[9:12])  # Last 3 are translation

    if len(fixed_parameters) > 0:
        affine_transform.SetFixedParameters(fixed_parameters)

    return affine_transform


def process_and_save_time_point(t, sitk_moving_4d_image, sitk_fixed_image, affine_transform, transformed_4d_image):
    """
    Process, transform the time point 't' from the 4D image, and write to memmap.
    Extracts a 3D slice, resamples it, and writes the transformed array to memmap.
    """
    extract_size = list(sitk_moving_4d_image.GetSize())
    extract_size[-1] = 0  # Set the time dimension to 0 to extract a 3D slice
    extract_index = [0, 0, 0, t]

    # Extract and transform
    sitk_moving_image_3d = sitk.Extract(sitk_moving_4d_image, extract_size, extract_index)
    resampled_image_3d = sitk.Resample(
        sitk_moving_image_3d, sitk_fixed_image, affine_transform, sitk.sitkLinear, 0.0,
        sitk_moving_image_3d.GetPixelID()
    )

    # Convert to array and write directly to memmap
    transformed_array = sitk.GetArrayFromImage(resampled_image_3d).transpose(2, 1, 0)[79:81, :, :]
    transformed_4d_image[:, :, :, t] = transformed_array  # Directly save to memory-mapped file


def main(aligned_2d_file, corrected_ts_file, transform_mtx_file, task_dir, output_filename='transformed_4d_image.dat', npy_filename='transformed_timeseries.npy'):
    """
    Main function to process and transform the 4D image and save the results.
    """
    # Validate files in a single function call
    validate_files(
        (aligned_2d_file, 'Aligned 2D file'),
        (corrected_ts_file, 'Corrected time series file'),
        (transform_mtx_file, 'Transformation matrix file')
    )
    print("All files found. Processing...")

    try:
        sitk_moving_4d_image = sitk.ReadImage(corrected_ts_file)
        sitk_fixed_image = sitk.ReadImage(aligned_2d_file)

        affine_transform = load_transform_matrix(transform_mtx_file)
        num_timepoints = sitk_moving_4d_image.GetSize()[-1]  # Last dimension is the time axis

        # Memory-mapped file to save the transformed 4D image
        shape_3d = (2, sitk_fixed_image.GetSize()[1], sitk_fixed_image.GetSize()[2], num_timepoints)
        transformed_4d_image = np.memmap(output_filename, dtype='float32', mode='w+', shape=shape_3d)

        # Process and save time points in parallel with a progress bar
        with tqdm_joblib(tqdm(total=num_timepoints, desc="Processing and saving time points")):
            Parallel(n_jobs=-1)(
                delayed(process_and_save_time_point)(
                    t, sitk_moving_4d_image, sitk_fixed_image, affine_transform, transformed_4d_image
                ) for t in range(num_timepoints)
            )

        # Flush data to disk
        transformed_4d_image.flush()
        print("Starting saving to disk...")
        # Save the final result to an .npy file
        final_transformed_4d_image = np.memmap(output_filename, dtype='float32', mode='r', shape=shape_3d)
        np.save(os.path.join(task_dir, npy_filename), final_transformed_4d_image)

        print("Done!")

    finally:
        if os.path.exists(output_filename):
            os.remove(output_filename)


if __name__ == "__main__":
    load_dotenv()
    base_dir = os.getenv('BASE_DIR')
    task_dir = os.path.join(base_dir, 'task_data')
    register_dir = os.path.join(base_dir, 'slice2chunk_grouper', '061824_1-5')

    aligned_2d_file = os.path.join(register_dir, 'Grouper_livemarmoset_0618_2D_corrected-transformed.nii.gz')
    corrected_ts_file = os.path.join(register_dir, 'Grouper_livemarmoset_0618_2D_timepoints_corrected.nii.gz')
    transform_mtx_file = os.path.join(register_dir, 'Transform.h5')

    main(aligned_2d_file, corrected_ts_file, transform_mtx_file, task_dir)