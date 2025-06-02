
import pandas as pd
import numpy as np
import ast
from os import path




def add_oe_event_path_to_csv(video_paths_csv):
    video_df = pd.read_csv(video_paths_csv)
    
    export_status_csv = "/home/lapishla/Desktop/pv_videos/katieExport/recordingSettings_completed_all.csv"
    oe_export_df = pd.read_csv(export_status_csv)

    oe_exp_names = []
    for p in oe_export_df.dataPath:
        oe_exp_names.append(path.split(path.dirname(p))[1])

    video_exp_name = []
    for p in video_df.path:
        video_exp_name.append(path.split(p)[1])

    export_folder = []
    for p in oe_export_df.output_path:
        export_folder.append(path.split(p)[1])

    video_event_export = []
    for video_exp in video_exp_name:
        try:
            i = oe_exp_names.index(video_exp)
            video_event_export.append(export_folder[i])
        except ValueError:
            video_event_export.append("")

    video_df['oe_export_folder'] = video_event_export
    video_df.to_csv(video_paths_csv)


video_paths_csv = "/home/lapishla/Desktop/pv_videos/Anymaze_of_interest.csv"
add_oe_event_path_to_csv(video_paths_csv)

def add_cropped_video_path_to_csv(video_paths_csv):
    df = pd.read_csv(video_paths_csv)

    output_folder = "/home/lapishla/Desktop/pv_videos/cropped_video/"
    output_path = []
    for id in df.ID:
        output_filename = f"{id}.mp4"
        output_path.append(os.path.join(output_folder, output_filename))
    df['cropped_video'] = output_path
    df.to_csv(video_paths_csv, index=False)

def get_points_as_np_array(df):
    for points in df.corner_points: # get points back into array. Probably need to find more robust file than csv.
        array = np.array(ast.literal_eval(points))