# create neurodocker container
conda create -n neurodocker python=3.9
conda activate neurodocker
python -m pip install neurodocker
neurodocker --help

# build afni container
apptainer build afni.sif docker://afni/afni_make_build

# neurodocker build failed
neurodocker generate singularity \
    --pkg-manager apt \
    --base-image neurodebian:bullseye \
    --miniconda version=latest conda_install="nipype notebook" \
    --install afni ants git vim \
    --user nonroot