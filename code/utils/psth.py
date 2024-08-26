import numpy as np
import pandas as pd
from tqdm import tqdm

def find_nearest_index(value, index, tolerance=0.2):
    diffs = np.abs(index - value)
    nearest_idx = np.argmin(diffs)
    
    if diffs[nearest_idx] <= tolerance:
        return index[nearest_idx]
    return None


# Function to map events to frame times
def map_events_to_frame_times(event_df, frame_times):
    event_binary_df = pd.DataFrame(index=frame_times.round(1))
    
    onset_indices = event_df['onset'].apply(find_nearest_index, index=event_binary_df.index, tolerance=0.40)
    end_indices = event_df['end'].apply(find_nearest_index, index=event_binary_df.index, tolerance=0.40)

    event_df['nearest_index_onset'] = onset_indices
    event_df['nearest_index_end'] = end_indices
    
    valid_events = (end_indices < event_binary_df.index[-1]) & onset_indices.notna() & end_indices.notna()

    for i, valid in event_df[valid_events].iterrows():
        nearest_index_onset = valid['nearest_index_onset']
        nearest_index_end = valid['nearest_index_end']
        existing_values = event_binary_df.loc[nearest_index_onset:nearest_index_end, :]

        if not (existing_values == 1).any().any():
            event_binary_df.loc[nearest_index_onset:nearest_index_end, valid['trial_type']] = 1
        else:
            print(f"Overlap detected for trial {valid['trial_type']} at indices {nearest_index_onset}:{nearest_index_end}")
    
    event_binary_df.rename(columns={'5': 'reward', '6': 'airpuff', '7': 'idle'}, inplace=True)
    
    return event_df.dropna(subset=['nearest_index_onset']), event_binary_df


def get_trial_data(event_df, offset_start, offset_end, pixel_data, tr=1/2.5):
    onset_indices = event_df['nearest_index_onset'].values
    indices = [np.arange(i + offset_start, i + offset_end, step=tr) for i in onset_indices]

    slice_length = len(indices[0]) * pixel_data.shape[1]
    trial_data = np.full((len(event_df), slice_length), np.nan)

    for i, idx_range in enumerate(indices):
        valid_idx_range = (idx_range / tr).astype(int)
        valid_idx_range = valid_idx_range[(valid_idx_range >= 0) & (valid_idx_range < pixel_data.shape[0])]
        
        data = pixel_data[valid_idx_range, :].flatten()
        if len(data) > slice_length:
            data = data[:slice_length]
        elif len(data) < slice_length:
            data = np.pad(data, (0, slice_length - len(data)), 'constant', constant_values=np.nan)
        
        trial_data[i, :len(data)] = data

    return trial_data

def normalize_data(data):
    baseline = np.nanmean(data[:, :12], axis=1, keepdims=True)
    task_data = np.divide(data - baseline, baseline, out=np.zeros_like(data), where=baseline!=0)
    return task_data

def proc_pixel(pixel_data, event_df, tr=1/2.5):
    trial_data = get_trial_data(event_df, pixel_data, tr)
    normalized_data = []

    for trial_type in event_df['trial_type'].unique():
        data = trial_data[event_df['trial_type'] == trial_type]
        normalized_data.append(normalize_data(data))
    
    return normalized_data  # returns a list [reward_data_normalized, airpuff_data_normalized, idle_data_normalized]

def get_trial_mean(data, start, end):
    return np.nanmean(data[:, start:end], axis=(0, 1)) if data.size > 0 else np.nan

def process_activation(Y, event_df, n_pixels, start, end, desc="Processing Pixels"):
    activation_normalized = np.zeros((n_pixels, 3))

    for i in tqdm(range(n_pixels), desc=desc):
        pixel_data = Y[i, :].reshape(-1, 1)
        normalized_data = proc_pixel(pixel_data, event_df)

        for j in range(3):  # Iterate over reward, airpuff, idle
            activation_normalized[i, j] = get_trial_mean(normalized_data[j], start, end)

    return activation_normalized