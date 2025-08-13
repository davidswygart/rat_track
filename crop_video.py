
import os
import subprocess
import numpy as np
import sys
from utilities import load_settings, get_video_info, overwrite_video_info, select_points
from collections import namedtuple

def main(job_folder):
    # generate IDs for videos
    video_info = get_video_info(job_folder)
    video_info['id'] = generate_unique_names(len(video_info))

    export_dir = os.path.join(job_folder, 'videos')
    os.makedirs(export_dir, exist_ok=True)
    video_info['cropped_path'] =  [os.path.join(export_dir,id+'.mp4') for id in video_info.id]

    crop_settings = load_settings(job_folder)['crop']
    for r in video_info.itertuples():
        # interactively choose cropping points
        point_names = ["upper left", "lower right"]
        points = select_points(r.video_path, point_names)

        # cropping string
        c = calc_crop_coordinates(points, crop_settings)
        crop = f"crop={c.width}:{c.height}:{c.x_start}:{c.y_start}"

        # scaling string
        sz = crop_settings['cropped_size']
        scale = f"scale={sz[0]}:{sz[1]}"

        # filter chain string
        filter_chain = f"{crop},{scale}"
        if (r.flip_xy):
            filter_chain = filter_chain + ",hflip,vflip"
        
        # Full FFmpeg command
        ffmpeg_cmd = [
            "ffmpeg",
            "-y", #automatically overwrite
            "-i", r.video_path,
            "-vf", filter_chain,
            "-c:a", "copy",
            "-an",
            r.cropped_path
        ]
        subprocess.run(ffmpeg_cmd, check=True)
        print(f"Successfully processed: {r.cropped_path}")
    overwrite_video_info(job_folder, video_info)


def calc_crop_coordinates(points, crop_settings):
    points = np.array(points)
    x = points[:,0]
    y = points[:,1]

    # calculate x points from reference and margin
    width = x.max() - x.min()
    margin = crop_settings['x_margin'] * width
    x_start = x.min() - margin
    x_stop = x.max() + margin
    width = x_stop - x_start

    # calculate y from reference and aspect ratio
    sz = crop_settings['cropped_size']
    height = width* sz[1] / sz[0]
    y_start = y.mean() - height/2

    # return relevant values in namedtuple
    Coordinates = namedtuple('Coordinates', ['width', 'height', 'x_start', 'y_start'])
    return Coordinates(width.round(), height.round(), x_start.round(), y_start.round())

def generate_unique_names(n):
    from datetime import datetime
    date_string = datetime.now().strftime("_%Y%m%d")
    return [str(s).zfill(3) + date_string for s in range(n)]


if __name__ == "__main__":
    job_folder = sys.argv[1]
    main(job_folder)
