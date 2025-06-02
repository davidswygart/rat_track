
import pandas as pd
import numpy as np
import ast
import os


video_paths_csv = "/home/lapishla/Desktop/pv_videos/Anymaze_of_interest.csv"
df = pd.read_csv(video_paths_csv)

# for points in df.corner_points: # get points back into array. Probably need to find more robust file than csv.
#     array = np.array(ast.literal_eval(points))


def add_cropped_video_path_to_csv(video_paths_csv):
    df = pd.read_csv(video_paths_csv)

    output_folder = "/home/lapishla/Desktop/pv_videos/cropped_video/"
    output_path = []
    for id in df.ID:
        output_filename = f"{id}.mp4"
        output_path.append(os.path.join(output_folder, output_filename))
    df['cropped_video'] = output_path
    df.to_csv(video_paths_csv, index=False)
