import os
import pandas as pd
import numpy as np
import nibabel as nib
import scipy.io as sio
from scipy.signal import butter, filtfilt, detrend
from scipy.ndimage import gaussian_filter1d

import numpy as np
from scipy.signal import detrend, butter, filtfilt
from scipy.ndimage import gaussian_filter1d

class FUSCleaner:
    def __init__(self, detrend=False, standardize=True, low_pass=None, high_pass=None, fs=2.5, sigma=1):
        """
        Initialize the FUSCleaner class with preprocessing parameters.
        
        Parameters:
        - detrend: bool, whether to detrend the data (remove linear trends)
        - standardize: bool, whether to apply z-score normalization
        - low_pass: float, the low-pass filter cutoff frequency in Hz (None to skip)
        - high_pass: float, the high-pass filter cutoff frequency in Hz (None to skip)
        - fs: float, the sampling frequency in Hz (default = 2.5)
        - sigma: float, standard deviation for temporal smoothing (default = 1)
        """
        self.detrend = detrend
        self.standardize = standardize
        self.low_pass = low_pass
        self.high_pass = high_pass
        self.fs = fs
        self.sigma = sigma

        # Validate filter parameters
        if self.low_pass and self.high_pass and self.low_pass <= self.high_pass:
            raise ValueError("low_pass should be greater than high_pass for a valid bandpass filter.")
        if self.low_pass and (self.low_pass <= 0 or self.low_pass >= 0.5 * fs):
            raise ValueError(f"low_pass must be between 0 and {0.5 * fs} Hz.")
        if self.high_pass and (self.high_pass <= 0 or self.high_pass >= 0.5 * fs):
            raise ValueError(f"high_pass must be between 0 and {0.5 * fs} Hz.")
    
    def clean(self, data):
        """
        Clean the fUS data according to the initialized parameters.
        
        Parameters:
        - data: 4D numpy array of shape (x, y, z, n_TR) representing the time series data.
        
        Returns:
        - Cleaned data.
        """
        self._check_data(data)

        # Step 1: Detrending (if specified)
        if self.detrend:
            data = self.detrend_data(data)
        
        # Step 2: Bandpass filtering (if high_pass or low_pass are specified)
        if self.low_pass or self.high_pass:
            data = self.bandpass_filter(data)

        # Step 3: Temporal smoothing
        data = self.temporal_smoothing(data)

        # Step 4: Z-score normalization (if specified)
        if self.standardize:
            data = self.z_score_normalize(data, detrended=self.detrend)

        return data

    def detrend_data(self, data):
        """ Detrend the data along the time axis (n_TR). """
        try:
            return detrend(data, axis=-1)  # Apply detrending along the time axis
        except Exception as e:
            raise ValueError(f"Detrending failed: {e}")

    def bandpass_filter(self, data):
        """ Apply bandpass, high-pass, or low-pass filtering along the time axis. """
        nyquist = 0.5 * self.fs
        low = self.high_pass / nyquist if self.high_pass else None
        high = self.low_pass / nyquist if self.low_pass else None

        if low and high:
            btype = 'band'
            cutoff = [low, high]
        elif low:
            btype = 'high'
            cutoff = low
        elif high:
            btype = 'low'
            cutoff = high
        else:
            return data  # No filtering

        try:
            b, a = butter(5, cutoff, btype=btype)
            return filtfilt(b, a, data, axis=-1)  # Apply filtering along the time axis
        except Exception as e:
            raise ValueError(f"Filtering failed: {e}")

    def temporal_smoothing(self, data):
        """ Apply temporal smoothing along the time axis using a Gaussian filter. """
        try:
            return gaussian_filter1d(data, sigma=self.sigma, axis=-1)  # Smoothing along the time axis
        except Exception as e:
            raise ValueError(f"Temporal smoothing failed: {e}")

    def z_score_normalize(self, data, detrended=False):
        """
        Z-score normalize the data, with special handling if it's already detrended.
        
        Parameters:
        - data: 4D numpy array of shape (x, y, z, n_TR)
        - detrended: bool, whether the data has already been detrended (skip mean subtraction)
        
        Returns:
        - Z-scored data.
        """
        if detrended:
            std = np.std(data, axis=-1, keepdims=True)
        else:
            mean = np.mean(data, axis=-1, keepdims=True)
            std = np.std(data, axis=-1, keepdims=True)
            data = data - mean  # Subtract mean
        
        std[std == 0] = 1  # Avoid division by zero
        
        try:
            return data / std
        except Exception as e:
            raise ValueError(f"Z-scoring failed: {e}")

    def _check_data(self, data):
        """
        Validate the input data.
        
        Parameters:
        - data: 4D numpy array to be cleaned.
        """
        if not isinstance(data, np.ndarray):
            raise ValueError("Input data must be a numpy array.")
        if data.ndim != 4:
            raise ValueError("Input data must be a 4D array of shape (x, y, z, n_TR).")
        if data.shape[-1] <= 1:
            raise ValueError("Time dimension (n_TR) must be greater than 1.")


def load_data(data_dir, brain_filename, event_filename):
    brain_file = os.path.join(data_dir, brain_filename)
    event_file = os.path.join(data_dir, event_filename)

    brain_data = nib.load(brain_file).get_fdata()
    print(f"Brain data shape: {brain_data.shape}")

    event_mat = sio.loadmat(event_file)['mldata'][0][0][0]

    return brain_data, event_mat

def extract_event_info(event_mat, method='glm'):
    if method == 'glm':
        behave_codes = event_mat[:]["BehavioralCodes"]
        absolute_starttime = event_mat[:]["AbsoluteTrialStartTime"]
    elif method == 'psth':
        behave_codes = event_mat[:]["BehavioralCodes"][1:]
        absolute_starttime = event_mat[:]["AbsoluteTrialStartTime"][1:]
    else:
        raise ValueError('Invalid method. Must be either "glm" or "psth".')
    return behave_codes, absolute_starttime

def create_event_dataframe(behave_codes, absolute_starttime, method="glm"):
    if method not in ["glm", "psth"]:
        raise ValueError("Method must be either 'glm' or 'psth'.")

    if method == "glm":
        event_df = pd.DataFrame(columns=['onset', 'trial_type', 'duration', 'raw_onset'], index=range(len(behave_codes)))

        for i, (b, s) in enumerate(zip(behave_codes, absolute_starttime)):
            trial_start = s[0][0]
            if i == 0:
                trial_type = b[0][0][1][4][0]
                stimulus_onset = b[0][0][0][4] + trial_start
            else:
                trial_type = b[0][0][1][2][0]
                stimulus_onset = b[0][0][0][2] + trial_start

            event_df.at[i, 'raw_onset'] = stimulus_onset / 1000
            event_df.at[i, 'trial_type'] = str(trial_type)
            event_df.at[i, 'duration'] = 2

        event_df['onset'] = event_df['raw_onset'] - absolute_starttime[0][0] / 1000

    elif method == "psth":
        event_df = pd.DataFrame(columns=['onset', 'trial_type', 'duration', 'end'], index=range(len(behave_codes)))

        for i, (b, s) in enumerate(zip(behave_codes, absolute_starttime)):
            trial_start = s[0][0]
            trial_type = b[0][0][1][2][0]
            trial_end = b[0][0][0][3] + trial_start
            stimulus_onset = b[0][0][0][2] + trial_start
            event_df.at[i, 'onset'] = stimulus_onset / 1000 - 6
            event_df.at[i, 'trial_type'] = str(trial_type)
            event_df.at[i, 'duration'] = 8
            event_df.at[i, 'end'] = trial_end / 1000

        event_df['end'] = event_df['end'].astype(float).round(1)
        event_df['onset'] = event_df['onset'].astype(float).round(1)
    
    return event_df
