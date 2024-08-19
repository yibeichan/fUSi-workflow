import os
import pandas as pd
import nibabel as nib
import scipy.io as sio

def load_data(data_dir, brain_filename, event_filename):
    brain_file = os.path.join(data_dir, brain_filename)
    event_file = os.path.join(data_dir, event_filename)

    brain_img = nib.load(brain_file)
    brain_data = brain_img.get_fdata()
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
