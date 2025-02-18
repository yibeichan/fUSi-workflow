import os
from glob import glob
import scipy.io as sio
import nibabel as nib
import numpy as np
from scipy import signal

def get_data(data_dir):
    brain_file = glob(os.path.join(data_dir, "*.nii"))[0]
    event_file = glob(os.path.join(data_dir, "*.mat"))[0]
    matdata = sio.loadmat(event_file)['mldata'][0][0][0]
    return brain_file, matdata

def load_nifti(nifti_path):
    img = nib.load(nifti_path)
    return np.squeeze(img.get_fdata()) 

def log_transform(data):
    min_val = np.min(data[data > 0])
    data_pos = data + min_val/2
    return np.log(data_pos)

def highpass_filter(data, sampling_rate, cutoff=0.01):
    nyquist = sampling_rate / 2
    b, a = signal.butter(2, cutoff/nyquist, btype='high')
    
    filtered_data = np.zeros_like(data)
    for x in range(data.shape[0]):
        for y in range(data.shape[1]):
            filtered_data[x,y,:] = signal.filtfilt(b, a, data[x,y,:])
    return filtered_data

def extract_trial_info(matdata, condition_type='all', n_trials=30, skip_first=True):
    """
    Extract trial information with condition filtering
    
    Parameters:
        matdata: MATLAB data structure
        condition_type: str, 'all', 'partner', 'object', 'stranger'
        n_trials: int, number of trials to extract
        skip_first: bool, whether to skip first trial
    """
    events_by_condition = {1: [], 2: [], 3: []}  # Partner, Object, Stranger
    
    for trial in matdata:
        block_type = trial["Block"][0][0]
        absolute_time = trial["AbsoluteTrialStartTime"][0][0] / 1000
        code_times = trial["BehavioralCodes"][0]['CodeTimes'][0]
        code_numbers = trial["BehavioralCodes"][0]['CodeNumbers'][0]
        
        code9_idx = np.where(code_numbers == 9)[0]
        if len(code9_idx) == 0:
            continue
            
        trial_start = absolute_time + code_times[code9_idx[0]][0]/1000
        
        trial_info = {
            'trial_start': trial_start,
            'condition': block_type,
            'codes': {},
            'duration': None  # Will be filled after processing codes
        }
        
        for num, time in zip(code_numbers, code_times):
            trial_info['codes'][int(num[0])] = trial_start + (time[0]/1000 - code_times[code9_idx[0]][0]/1000)
        
        # Calculate trial duration
        if 1 in trial_info['codes']:
            trial_info['duration'] = 5
        elif 2 in trial_info['codes'] and 3 in trial_info['codes']:
            trial_info['duration'] = trial_info['codes'][3] - trial_info['codes'][2]
            
        events_by_condition[block_type].append(trial_info)
    
    # Select trials based on condition_type
    if condition_type == 'all':
        selected_trials = []
        for condition in events_by_condition.values():
            selected_trials.extend(condition)
    else:
        condition_map = {'partner': 1, 'object': 2, 'stranger': 3}
        selected_trials = events_by_condition[condition_map[condition_type]]
    
    # Sort by trial start time
    selected_trials.sort(key=lambda x: x['trial_start'])
    
    # Skip first trial if requested
    if skip_first:
        selected_trials = selected_trials[1:]
    
    # Select specified number of trials
    selected_trials = selected_trials[:n_trials]
    
    return selected_trials

def get_matched_live_trials(live_events, partner_trials, n_trials=None):
    """
    Match live trials to partner trials by count and duration
    
    Parameters:
        live_events: list of live social trial events
        partner_trials: list of partner condition trials
        n_trials: optional number of trials to match (default: len(partner_trials))
    """
    if n_trials is None:
        n_trials = len(partner_trials)
    
    # Get total duration of partner trials (should be 5s each)
    partner_total_duration = n_trials * 5
    
    # Sort live trials by duration to optimize matching
    live_events = sorted(live_events, key=lambda x: x['duration'])
    
    matched_trials = []
    current_duration = 0
    
    for trial in live_events:
        if len(matched_trials) >= n_trials or current_duration >= partner_total_duration:
            break
        matched_trials.append(trial)
        current_duration += trial['duration']
    
    return matched_trials[:n_trials]

def get_iti_mask(events, n_timepoints, sampling_rate, n_trials=30):
    iti_mask = np.ones(n_timepoints, dtype=bool)
    
    for event in events[:n_trials]:
        # Mask out trial periods only
        if 1 in event['codes']:  # Video
            start_idx = int(event['codes'][1] * sampling_rate)
            end_idx = start_idx + int(5 * sampling_rate)
        else:  # Live
            start_idx = int(event['codes'][2] * sampling_rate)
            end_idx = int(event['codes'][3] * sampling_rate)
            
        if end_idx < n_timepoints:
            iti_mask[start_idx:end_idx] = False
    
    return iti_mask

def calculate_baseline(data, iti_mask):
    """Calculate baseline from ITI periods"""
    baseline = np.zeros(data.shape[:-1])
    for x in range(data.shape[0]):
        for y in range(data.shape[1]):
            iti_values = data[x,y,iti_mask]
            baseline[x,y] = np.median(iti_values)
    return baseline

def calculate_psc(data, baseline):
    """Calculate percent signal change.
    
    Parameters:
        data: array of shape (x, y, time)
        baseline: array of shape (x, y) or (x, y, 1)
    """
    # Ensure baseline has correct shape for broadcasting
    if baseline.ndim == 2:
        baseline = baseline[..., None]  # Add time dimension
    elif baseline.shape[-1] == 1:
        pass  # Already correct shape
    else:
        raise ValueError("Baseline should be 2D or have last dimension of size 1")
        
    return (data - baseline) / baseline * 100


def extract_trial_timepoints(events, n_trials, sampling_rate, skip_first=True):
    """
    Extract timepoints corresponding to trials
    
    Parameters:
        events: list of trial events
        n_trials: number of trials to extract
        sampling_rate: sampling rate of the data
        skip_first: bool, whether to skip first trial
    """
    total_trials = len(events)
    
    if skip_first:
        if total_trials <= 1:
            raise ValueError("Not enough trials to skip first trial")
        start_trial_idx = 1
        available_trials = total_trials - 1
    else:
        start_trial_idx = 0
        available_trials = total_trials
    
    if n_trials > available_trials:
        print(f"Warning: Requested {n_trials} trials but only {available_trials} available. Using all available trials.")
        n_trials = available_trials
    
    end_trial_idx = start_trial_idx + n_trials
    
    first_trial_start = int(events[start_trial_idx]['codes'][1 if 1 in events[start_trial_idx]['codes'] else 2] * sampling_rate)
    last_trial_end = int(events[end_trial_idx-1]['codes'][18] * sampling_rate)
    
    return slice(first_trial_start, last_trial_end)

def plot_preprocessing_steps(data_dir, figsize=(25, 6)):
    """
    Plot heatmaps of brain data at each preprocessing step
    
    Parameters:
        data_dir: str, directory containing the data
        timepoint: int, timepoint to plot (default: 0)
        figsize: tuple, figure size (width, height)
    """
    import matplotlib.pyplot as plt
    
    # Get data and process each step
    brain_file, matdata = get_data(data_dir)
    raw_data = load_nifti(brain_file)
    
    # Calculate baseline and PSC in raw space
    events = extract_trial_info(matdata, condition_type='all', n_trials=None)
    iti_mask = get_iti_mask(events, raw_data.shape[-1], sampling_rate=4)
    raw_baseline = calculate_baseline(raw_data, iti_mask)
    data_psc = calculate_psc(raw_data, raw_baseline)
    
    # Then apply log transform to raw data and baseline
    data_log = log_transform(raw_data)
    log_baseline = log_transform(raw_baseline)
    data_psc_log = log_transform(data_psc + 100) - log_transform(np.array([100]))
    
    # Calculate z-scores
    # Z-score on log data (across time for each pixel)
    data_log_zscore = (data_log - np.mean(data_log, axis=2, keepdims=True)) / np.std(data_log, axis=2, keepdims=True)
    
    # Z-score on PSC data (across time for each pixel)
    data_psc_zscore = (data_psc - np.mean(data_psc, axis=2, keepdims=True)) / np.std(data_psc, axis=2, keepdims=True)
    
    # Create figure with subplots
    fig, axes = plt.subplots(2, 4, figsize=figsize)
    
    # Plot each processing step
    steps = [
        [('Raw', raw_data),
         ('Raw Baseline', raw_baseline),
         ('Raw PSC', data_psc),
         ('Log Z-score', data_log_zscore)],
        [('Log', data_log),
         ('Log Baseline', log_baseline),
         ('Log PSC', data_psc_log),
         ('PSC Z-score', data_psc_zscore)]
    ]
    
    for row_idx, row in enumerate(steps):
        for col_idx, (title, data) in enumerate(row):
            ax = axes[row_idx, col_idx]
            if data.ndim == 3:  # For 3D data, take mean across time
                im = ax.imshow(np.mean(data, axis=2).T, cmap='viridis')
            else:  # For 2D data (baseline)
                im = ax.imshow(data.T, cmap='viridis')
            ax.set_title(title)
            plt.colorbar(im, ax=ax)
            ax.axis('off')
    
    plt.tight_layout()
    return fig

def preprocess_single_condition(data_dir, condition_type='all', sampling_rate=4):
    brain_file, matdata = get_data(data_dir)
    data = load_nifti(brain_file)
    
    # Calculate baseline in raw space before log transform
    events = extract_trial_info(matdata, condition_type, n_trials=None)
    iti_mask = get_iti_mask(events, data.shape[-1], sampling_rate)
    baseline = calculate_baseline(data, iti_mask)
    
    # Then do log transform
    data_log = log_transform(data)
    baseline_log = log_transform(baseline)  # baseline is shape (x, y)
    
    # Calculate PSC
    data_psc = calculate_psc(data_log, baseline_log)  # Let calculate_psc handle the dimension
    
    return data_psc, events

def adjust_event_timings(events, slice_start, n_trials=30, event_type=None):
    """Adjust event timings and limit to n_trials"""
    adjusted_events = []
    
    # Debug prints
    print(f"\nAdjusting {event_type} events:")
    print(f"Slice start: {slice_start}")
    print(f"Number of input events: {len(events)}")
    
    for i, evt in enumerate(events[:n_trials]):
        new_evt = evt.copy()
        # Different onset code for video (1) vs live (2)
        onset_code = 1 if event_type == 'video' else 2
        
        # Debug individual event
        print(f"\nEvent {i}:")
        print(f"Codes: {evt.get('codes', 'No codes')}")
        print(f"Using onset_code: {onset_code}")
        
        if 'codes' in evt and len(evt['codes']) > onset_code:
            new_evt['onset'] = evt['codes'][onset_code] - slice_start
            new_evt['type'] = event_type
            print(f"Adjusted onset: {new_evt['onset']}")
            adjusted_events.append(new_evt)
        else:
            print(f"WARNING: Invalid codes for event {i}")
    
    print(f"\nTotal adjusted events: {len(adjusted_events)}")
    return adjusted_events

def check_adjusted_events(events_adjusted):
    print(f"First 5 onsets: {[evt['onset'] for evt in events_adjusted[:5]]}")
    print(f"First 5 durations: {[evt['duration'] for evt in events_adjusted[:5]]}")

def preprocess_fus_data(video_dir, live_dir=None, glm_type='all_vs_live', n_trials=30):
    video_data, video_events = preprocess_single_condition(video_dir, 
        'partner' if glm_type == 'partner_vs_live' else 'all')

    if glm_type != 'video_contrasts':
        live_data, live_events = preprocess_single_condition(live_dir, 'all')
        
        print("Before slicing:")
        print(f"Video data shape: {video_data.shape}")
        print(f"Live data shape: {live_data.shape}")
        
        # First get the slices for both conditions
        video_slice = extract_trial_timepoints(video_events[:n_trials], n_trials, sampling_rate=4)
        
        if glm_type == 'partner_vs_live':
            live_events = get_matched_live_trials(live_events, video_events, n_trials=n_trials)
            
        live_slice = extract_trial_timepoints(live_events[:n_trials], n_trials, sampling_rate=4)
        
        # Debug first few events
        print("First video event:")
        print(f"Slice start: {video_events[0]['codes'][1]}")
        print(f"Raw onset: {video_events[0]['codes'][1]}")
        print(f"Adjusted onset: {video_events[0]['codes'][1] - video_events[0]['codes'][1]}")

        print("\nFirst live event:")
        print(f"Slice start: {live_events[0]['codes'][2]}")
        print(f"Raw onset: {live_events[0]['codes'][2]}")
        print(f"Adjusted onset: {live_events[0]['codes'][2] - live_events[0]['codes'][2]}")

        # Then adjust timings relative to slice starts
        video_events_adjusted = adjust_event_timings(video_events, 
                                                   video_events[0]['codes'][1], 
                                                   n_trials,
                                                   'video')
        live_events_adjusted = adjust_event_timings(live_events,
                                                       live_events[0]['codes'][2],
                                                       n_trials,
                                                       'live')
        print(f"Video events adjusted: {len(video_events_adjusted)} trials")
        print(f"Live events adjusted: {len(live_events_adjusted)} trials")

        print("Video events:")
        check_adjusted_events(video_events_adjusted)
        print("\nLive events:")
        check_adjusted_events(live_events_adjusted)

        return {
            'video_data': video_data[..., video_slice],
            'live_data': live_data[..., live_slice],
            'video_events': video_events_adjusted,
            'live_events': live_events_adjusted
        }
    
    # For video_contrasts, still need to adjust timings
    video_events_adjusted = adjust_event_timings(video_events, 
                                               video_events[0]['codes'][1],
                                               n_trials,
                                               'video')
    return {
        'video_data': video_data,
        'video_events': video_events_adjusted
    }