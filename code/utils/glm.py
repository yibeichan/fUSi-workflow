import numpy as np
import pandas as pd
from nilearn.glm.first_level import make_first_level_design_matrix, run_glm
from nilearn.glm.contrasts import compute_contrast
import matplotlib.pyplot as plt
import seaborn as sns

def run_glm_analysis(brain_data, event_df, tr=1/2.5, hrf_model='glover'):
    n_tr = brain_data.shape[-1]
    frame_times = np.arange(n_tr) * tr

    X = make_first_level_design_matrix(
        frame_times=frame_times,
        events=event_df,
        drift_model='polynomial',
        drift_order=3,
        hrf_model=hrf_model
    )

    Y = brain_data.reshape(-1, brain_data.shape[-1])
    labels, estimators = run_glm(Y.T, X.values)
    
    return labels, estimators, X

def compute_contrasts(labels, estimators, X):
    # this function only applys to the reward-airpuff-idle task after 05/23/2024
    contrast_matrix = np.eye(X.shape[1])
    basic_contrasts = dict([(column, contrast_matrix[i]) for i, column in enumerate(X.columns)])
    contrast = {
        'reward': basic_contrasts['5'],
        'airpuff': basic_contrasts['6'],
        'idle': basic_contrasts['7'],
        'reward - airpuff': basic_contrasts['5'] - basic_contrasts['6'],
        'reward - idle': basic_contrasts['5'] - basic_contrasts['7'],
        'airpuff - idle': basic_contrasts['6'] - basic_contrasts['7'],
    }

    contrast_results = {key: None for key in contrast.keys()}
    for contrast_id, contrast_value in contrast.items():
        contrast_result = compute_contrast(labels, estimators, contrast_value, stat_type='t')
        contrast_results[contrast_id] = contrast_result.z_score()
    
    return contrast_results

def plot_contrasts(contrast_results, brain_shape):
    # this function only applys to the reward-airpuff-idle task after 05/23/2024
    # and only plots 6 contrasts
    fig, axes = plt.subplots(2, 3, figsize=(15, 10))
    axes = axes.flatten()

    for i, (key, value) in enumerate(contrast_results.items()):
        sns.heatmap(value.reshape(brain_shape[0], brain_shape[2]).T, ax=axes[i], cmap="bwr", vmin=-15, vmax=15)
        axes[i].set_title(key)

    plt.tight_layout()
    plt.show()
    