import cv2
import pandas as pd
import sys


# Requires csv file path as first argument
def main():
    print("Starting the script...")
    # Read the CSV file
    csv_file = sys.argv[1]
    df = pd.read_csv(csv_file)

    # Initialize columns for coordinates
    df['corner_points'] = ''
    df['light_points'] = ''

    # Loop through each video file path
    for index, row in df.iterrows():
        video_path = row['full_file']
        print(f"Processing: {video_path}")
        points = select_points(video_path)
        if points:
            df.at[index, 'corner_points'] = str(points['corner'])
            df.at[index, 'light_points'] = str(points['light'])
            
        # Save the updated CSV file
        df.to_csv('updated_video_paths.csv', index=False)
        print("Updated CSV file saved as 'updated_video_paths.csv'.")

def select_points(video_path):
    cap = cv2.VideoCapture(video_path)
    ret, frame = cap.read()
    if not ret:
        print(f"Failed to read video: {video_path}")
        return None

    clone = frame.copy()
    points = {'corner': [], 'light': []}
    temp_points = []

    def click_event(event, x, y, flags, param):
        nonlocal frame
        if event == cv2.EVENT_LBUTTONDOWN:
            if len(temp_points) < 6:
                temp_points.append((x, y))
                print("select the 4 corner points")
                if len(temp_points) <= 4:
                    points['corner'].append((x, y))
                    cv2.circle(frame, (x, y), 5, (255, 0, 0), -1)  # Blue for corners
                else:
                    print("select the 2 lights")
                    points['light'].append((x, y))
                    cv2.circle(frame, (x, y), 5, (0, 0, 255), -1)  # Red for lights
                cv2.imshow('Frame', frame)

    while True:
        frame = clone.copy()
        temp_points.clear()
        points['corner'].clear()
        points['light'].clear()

        cv2.imshow('Frame', frame)
        cv2.setMouseCallback('Frame', click_event)

        while True:
            key = cv2.waitKey(0)
            if key == ord('r'):
                break  # Restart selection
            elif key == 32:  # SPACE key to confirm and exit
                cv2.destroyAllWindows()
                return points


if __name__ == "__main__":
    main()
