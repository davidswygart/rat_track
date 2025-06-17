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
    for video_path in df.video_path:
        print(f"Processing: {video_path}")
        points.append(select_points(video_path, point_names))

    df['poi_names'] = [point_names] * len(df)
    df['poi_xy_raw'] = points    
    # Save the updated CSV file
    df.to_csv(csv_file, index=False)
    print(f"saved: {csv_file}")

def select_points(video_path, point_names):
    cap = cv2.VideoCapture(video_path)
    ret, frame = cap.read()
    if not ret:
        print(f"Failed to read video: {video_path}")
        return None
    
    points = []
    def show_frame():
        for p in points:
            cv2.circle(frame, p, 5, (0, 255, 0), -1)
        cv2.imshow('Frame', frame)
        if len(points) >= len(point_names):
            print("All points selected.")
            print("Click 'r' to restart selection or SPACE to confirm and exit.")
        else:
            print(f"Click {point_names[len(points)]}")

    def click_event(event, x, y, flags, param):
        if len(points) < len(point_names):
            if event == cv2.EVENT_LBUTTONDOWN:
                points.append((x, y))
                show_frame()


    print("Click 'r' to restart selection or SPACE to confirm and exit.")
    show_frame()
    cv2.setMouseCallback('Frame', click_event)
    
    while True:
        key = cv2.waitKey(0)
        if key == ord('r'):
            return select_points(video_path, point_names)
        elif key == 32:  # SPACE key to confirm and exit
            if len(points) < len(point_names):
                print("Not enough points selected. Please select all points.")
            else:
                cv2.destroyAllWindows()
                return points


if __name__ == "__main__":
    main()
