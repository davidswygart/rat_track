import pandas as pd
import os
import subprocess
import ast
import numpy as np

# Load the CSV file
csv_file = "/home/lapishla/Desktop/pv_videos/updated_video_paths.csv"
output_folder = "/home/lapishla/Desktop/pv_videos/cropped_video/"
os.makedirs(output_folder, exist_ok=True)

# Read the CSV data
df = pd.read_csv(csv_file)

# Iterate through each row and process the video
for index, row in df.iterrows():
    video_path = row["full_file"]
    output_filename = f"{row['ID']}.mp4"
    output_path = os.path.join(output_folder, output_filename)
    
    
    # Extract cropping coordinates (assuming "light_points" contains "x:y:w:h")
    try:
        light_points = ast.literal_eval(row["light_points"])
        light_points = np.array(light_points)
        x_points = light_points[:,0]
        min_x = min(x_points) 
        max_x = max(x_points)

        width = max_x - min_x
        

        y_points = light_points[:,1]
        height = width*3/5
        avg_y = int(np.average(y_points)) 
        min_y = int(avg_y - height/2)

    except ValueError:
        print(f"Skipping row {index}: Invalid light_points format")
        continue

    # FFmpeg command to crop the video
    ffmpeg_cmd = [
        "ffmpeg",
         "-y", #automatically overwrite
         "-i", video_path,
         "-vf", f"crop={width}:{height}:{min_x}:{min_y},scale=500:300",
        "-c:a", "copy",
        "-an",
        output_path
    ]

    # Execute FFmpeg command
    try:
        subprocess.run(ffmpeg_cmd, check=True)
        print(f"Successfully processed: {output_filename}")
    except subprocess.CalledProcessError:
        print(f"Error processing {video_path}")

print("Processing complete.")

