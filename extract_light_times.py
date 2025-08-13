#! /home/lapishla/miniconda3/envs/openCV/bin/python3
import cv2
import numpy as np
import pandas as pd
import os
import sys
from utilities import load_settings, get_video_info, overwrite_video_info, select_points


def main(job_folder):
    video_info = get_video_info(job_folder)
    point_names = ["left light", "right light"]

    for path in video_info.cropped_path:
        points = select_points(path, point_names)
        events= get_events(path, points)
        export_path= path + '_light_events.csv'
        events.to_csv(export_path)
        print(f'exported {export_path}')


def get_events(video_path, points):
    # analyze left light
    luminosity = measure_luminosity(video_path, points[0])
    (L_frame, L_state) = analyze_signal(luminosity)
    print(f'{len(L_frame)} events found for left light')

    # analyze right light
    luminosity = measure_luminosity(video_path, points[1])
    (R_frame, R_state)  = analyze_signal(luminosity)
    print(f'{len(R_frame)} events found for right light')

    # Combine into dataframe
    frame = L_frame + R_frame
    state = L_state + R_state
    side = ['L']*len(L_state) + ['R']*len(R_state)

    table = pd.DataFrame({'frame':frame, 'state':state, 'side':side})
    table = table.sort_values(by='frame')
    return table

def measure_luminosity(video_path, point):
    """
    Opens a video file and measures the average luminosity in a rectangular region.
    Args:
        video_path (str): Path to the video file.
        point (list): XY point of light
    Returns:
        List of average luminosity values per frame.
    """
    cap = cv2.VideoCapture(video_path)

    # Choose width and height of bounding box
    frame_width = int(cap.get(cv2.CAP_PROP_FRAME_WIDTH))
    frame_height = int(cap.get(cv2.CAP_PROP_FRAME_HEIGHT))
    width = 0.03*frame_width
    height = 0.1*frame_height

    # calculate x and y range, while staying in frame size
    x_min = max(int(point[0] - width/2), 0)
    x_max = min(int(point[0] + width/2), frame_width)
    y_min = max(int(point[1] - height/2), 0)
    y_max = min(int(point[1] + height/2), frame_height)
   

    avg_luminosity_values = []
    if not cap.isOpened():
        print("Error: Could not open video file.")
        return avg_luminosity_values
    while True:
        ret, frame = cap.read()
        if not ret:
            break  # End of video
        gray_frame = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)
        region = gray_frame[y_min:y_max, x_min:x_max]
        avg_region = np.mean(region)
        avg_luminosity_values.append(avg_region)

        # import matplotlib.pyplot as plt
        # plt.imshow(region)
        # plt.show()
    cap.release()
    return avg_luminosity_values

def analyze_signal(signal, threshold=3, smooth=True, window_size=3, plot=False, xlim=None):
    """
    Analyzes digital signal to extract ON and OFF transition times.

    Parameters:
    signal (list): A list of values representing the digital signal.
    threshold (float): Threshold in standard deviations above median
    smooth (bool): Whether to smooth the signal using a moving average.
    window_size (int): The window size for the moving average (number of frames).
    plot (bool): Whether to plot graphs 

    Returns:
    dict: A dictionary containing ON and OFF transition times.
    """
    # make sure signal is a numpy array
    signal = np.array(signal) 

    # Apply smoothing if enabled
    if smooth:
        signal = np.convolve(signal, np.ones(window_size)/window_size, mode='valid')
    
    # Rescale the signal to have min value 0 and max value 1
    # signal = (signal - np.min(signal)) / (np.max(signal) - np.min(signal))

    # Detect transitions
    raw_thresh = np.median(signal) + np.std(signal)*threshold
    above_thresh = signal > raw_thresh
    cross_thresh = np.diff(above_thresh)

    # frame index after rising above threshold
    rising = np.flatnonzero(cross_thresh & above_thresh[1:]) + 1 
    # frame index after fallowing below threshold
    falling = np.flatnonzero(cross_thresh & ~above_thresh[1:]) + 1 

    if plot:
        plot_signal(signal, rising, falling, raw_thresh, xlim=xlim)

    if len(rising) != len(falling):
        raise ValueError("differing number of ON and OFF")
    
    length_ON = falling - rising
    if np.any(length_ON < 3):
        print(f'WARNING: light ON time of {np.min(length_ON)} frames detected')

    state = [1] * len(rising) + [0] * len(falling)
    frame_number = rising.tolist() + falling.tolist()
    return (frame_number, state)

def plot_signal(signal, rising, falling, raw_thresh, xlim=None):
    import matplotlib.pyplot as plt
    plt.figure(figsize=(10, 6))
    x = list(range(len(signal)))
    plt.scatter(x, signal, marker='.')
    plt.xlabel('Frame #')
    plt.ylabel('Luminosity')

    # Mark transitions
    y = np.ones(np.shape(rising)) * np.max(signal)
    plt.scatter(rising, y, color='green')
    y = np.ones(np.shape(falling)) * np.min(signal)
    plt.scatter(falling, y, color='red')

    # Mark threshold
    plt.hlines(raw_thresh, 0, len(signal), color='orange')

    if xlim:
        plt.xlim(xlim)
    plt.show()

def get_mp4_files(directory):
    mp4_files = []
    for filename in os.listdir(directory):
        if filename.endswith(".mp4"):
            full_path = os.path.join(directory, filename)
            mp4_files.append(full_path)
    return mp4_files

if __name__ == "__main__":
    job_folder = sys.argv[1]
    main(job_folder)