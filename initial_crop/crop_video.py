import pandas as pd
import os
import subprocess
import ast
import numpy as np
import sys
import yaml

def main():
    # Load the CSV file
    csv_file = sys.argv[1]
    df = pd.read_csv(csv_file)
    df['id'] = generate_unique_names(len(df))

    export_dir = os.path.dirname(csv_file) + '/videos/'
    os.makedirs(export_dir, exist_ok=True)
    df['video_path_cropped'] =  export_dir + df['id'] + '.mp4'

    # Load settings file
    yaml_file = os.path.dirname(__file__) + '/settings.yaml'
    with open(yaml_file, 'r') as f:
        settings = yaml.safe_load(f)

    # Iterate through each row and process the video
    new_pois = []
    for row in df.itertuples():
        try:
            pois = parse_points(row.poi_xy_original)
            settings = calc_crop_coordinates(settings, pois)
            crop_video(row, settings['crop'])
            new_pois.append(calc_poi_after_crop(settings['crop'], pois))
        except:
            print('failed')
            new_pois.append(None)
    df['frame_size_croppped'] = [(settings['crop']['x_pixels'] , settings['crop']['y_pixels'])]  * len(df)
    df['poi_xy_cropped'] = new_pois  
    df.to_csv(csv_file, index=False)
    print(f"saved: {csv_file}")   

def calc_poi_after_crop(settings, pois):
    x_relative = (pois[:,0] - settings['x_start']) / settings['width']
    x_absolute = x_relative * settings['x_pixels']
    y_relative = (pois[:,1] - settings['y_start']) / settings['height']
    y_absolute = y_relative * settings['y_pixels']
    poi_array = np.column_stack((x_absolute , y_absolute))
    return poi_array.round().astype(int).tolist()

def crop_video(row, settings):
    # FFmpeg command to crop the video
    crop = f"crop={settings['width']}:{settings['height']}:{settings['x_start']}:{settings['y_start']}"
    scale = f"scale={settings['x_pixels']}:{settings['y_pixels']}"

    if (row.flip_xy):
        filter_chain = f"hflip,vflip,{crop},{scale}"
    else:
        filter_chain = f"{crop},{scale}"
    
    ffmpeg_cmd = [
        "ffmpeg",
        "-y", #automatically overwrite
        "-i", row.video_path,
        "-vf", filter_chain,
        "-c:a", "copy",
        "-an",
        row.video_path_cropped
    ]
    subprocess.run(ffmpeg_cmd, check=True)
    print(f"Successfully processed: {row.video_path_cropped}")

def calc_crop_coordinates(settings, poi):
    # Get x and y reference points
    poi_names = settings['points_of_interest']
    ref_inds = [poi_names.index(n) for n in settings['crop']['x_points']]
    ref_x = poi[ref_inds, 0]
    ref_y = poi[ref_inds, 1]

    # calculate x points from reference and margin
    margin = settings['crop']['x_margin'] * (ref_x.max() - ref_x.min())
    x_start = ref_x.min() - margin
    x_stop = ref_x.max() + margin
    width = x_stop - x_start

    # calculate y from reference and aspect ratio
    aspect = settings['crop']['y_pixels'] / settings['crop']['x_pixels']
    height = width*aspect
    y_start = ref_y.mean() - height/2

    # add cropping values to map
    settings['crop']['x_start'] = int(x_start)
    settings['crop']['width'] = int(width)
    settings['crop']['y_start'] = int(y_start)
    settings['crop']['height'] = int(height)
    return settings

def generate_unique_names(n):
    from datetime import datetime
    date_string = datetime.now().strftime("_%Y%m%d")
    return [str(s).zfill(3) + date_string for s in range(n)]

def parse_points(points_xy_string):
    xy = ast.literal_eval(points_xy_string)
    return np.array(xy)


if __name__ == "__main__":
    main()
