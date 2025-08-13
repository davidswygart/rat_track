
import sys
from utilities import load_settings, get_video_info, overwrite_video_info, select_points

def main(job_folder):
    print("Starting the script...")
    point_names = load_settings(job_folder)['points_of_interest']
    video_info = get_video_info(job_folder)

    # Loop through each video file path
    points = []
    for r in video_info.itertuples():
        p = select_points(r.cropped_path, point_names)
        points.append(p)
    video_info['poi'] = points    
    
    # Save the updated CSV file
    overwrite_video_info(job_folder, video_info)



if __name__ == "__main__":
    job_folder = sys.argv[1]
    main(job_folder)
