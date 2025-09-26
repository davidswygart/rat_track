# import pandas as pd
# def match_and_update_paths(report_path, settings_path):
#     # Load both CSV files
#     report_df = pd.read_csv(report_path)
#     settings_df = pd.read_csv(settings_path)
#     # Ensure required columns exist
#     # if 'video_path' not in settings_df.columns or 'output_path' not in report_df.columns:
#     #     raise ValueError("Missing required columns: 'video_path' in settings or 'output_path' in report")
#     # Create a lookup set for fast matching
#     report_paths = set(report_df['dataPath'].astype(str))
#     # Prepare a new column to store matched output paths
#     matched_paths = []
#     for video_path in settings_df['video_path'].astype(str):
#         parts = video_path.strip().split('/')
#         if len(parts) < 2:
#             matched_paths.append(None)
#             continue
#         target_substring = parts[-2]
#         # Find the first matching full output_path
#         match = next((path for path in report_paths if target_substring in path), None)
#         matched_paths.append(match)
#     # Add the new column to settings_df
#     settings_df['matched_output_path'] = matched_paths
#     # Optionally save the updated settings CSV
#     settings_df.to_csv(settings_path, index=False)
#     return settings_df

import pandas as pd
def match_and_update_paths(report_path, settings_path):
    # Load both CSV files
    report_df = pd.read_csv(report_path)
    settings_df = pd.read_csv(settings_path)
    # Ensure required columns exist
    # if 'video path' not in settings_df.columns or 'dataPath' not in report_df.columns or 'output_path' not in report_df.columns:
    #     raise ValueError("Missing required columns: 'video path' in settings or 'dataPath'/'output_path' in report")
    # Convert report dataPath and output_path to strings
    report_df['dataPath'] = report_df['dataPath'].astype(str)
    report_df['output_path'] = report_df['output_path'].astype(str)
    # Prepare a new column to store matched output paths
    matched_paths = []
    for video_path in settings_df['video_path'].astype(str):
        parts = video_path.strip().split('/')
        if len(parts) < 2:
            matched_paths.append(None)
            continue
        target_substring = parts[-2]
        # Find the first row in report_df where dataPath contains the substring
        match_row = report_df[report_df['dataPath'].str.contains(target_substring, na=False)]
        if not match_row.empty:
            matched_paths.append(match_row.iloc[0]['output_path'])
        else:
            matched_paths.append(None)
    # Add the new column to settings_df
    settings_df['matched_output_path'] = matched_paths
    # Optionally save the updated settings CSV
    settings_df.to_csv(settings_path+"new.csv", index=False)
    return settings_df

match_and_update_paths("/home/lapishla/Desktop/katieExport2/recordingSettings_5676198.csv", "/home/lapishla/Desktop/dlc_crop2/videos.csv")