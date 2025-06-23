import cv2
import pandas as pd
import sys
import yaml
import os

# Requires csv file path as first argument
def main():
    print("Starting the script...")
    # Read the CSV file
    csv_file = sys.argv[1]
    df = pd.read_csv(csv_file)

    yaml_file = os.path.dirname(__file__) + '/settings.yaml'
    with open(yaml_file, 'r') as f:
        settings = yaml.safe_load(f)
    point_names = settings['points_of_interest']

    # Loop through each video file path
    points = []
    frame_size = []
    for row in df.itertuples():
        print(f"Processing: {row.video_path}")
        frame = get_frame(row.video_path, row.flip_xy)
        if frame is None:
            print(f"Error getting frame. skipping {row.video_path}")
            frame_size.append(None)
            points.append(None)
        else:
            frame_size.append((frame.shape[1], frame.shape[0]))
            points.append(select_points(frame, point_names))

    df['poi_names'] = [point_names] * len(df)
    df['frame_size_original'] = frame_size
    df['poi_xy_original'] = points    
    # Save the updated CSV file
    df.to_csv(csv_file, index=False)
    print(f"saved: {csv_file}")

def get_frame(file, flip=False):
    ret, frame = cv2.VideoCapture(file).read()
    if ret & flip:
        return frame[::-1, ::-1] # Flip x and y dimensions (same as rotating 180 degrees)
    else:
        return frame

def select_points(frame, point_names):    
    f = frame.copy() # save original frame in case the user needs to restart
    points = []

    def prompt_next_click():
        if len(points) < len(point_names):
            print(f"Click {point_names[len(points)]}, or type 'r' to restart selection")
            cv2.setMouseCallback('Frame', click_event)
        else:
            print("All points selected.")
            print("Click 'r' to restart selection or SPACE to confirm and exit.")
            cv2.setMouseCallback('Frame', lambda *args : None)

    def click_event(event, x, y, flags, param):
        if event == cv2.EVENT_LBUTTONDOWN:
            points.append((x, y))
            cv2.circle(f, (x,y), 5, (0,255,0), -1)
            cv2.imshow('Frame', f)
            prompt_next_click()

    cv2.imshow('Frame', f)
    prompt_next_click()
    
    while True:
        key = cv2.waitKey(0)
        if key == ord('r'):
            cv2.destroyAllWindows()
            return select_points(frame, point_names)
        elif key == 32:  # SPACE key to confirm and exit
            if len(points) < len(point_names):
                print("Not enough points selected. Please select all points.")
            else:
                cv2.destroyAllWindows()
                return points


if __name__ == "__main__":
    main()
