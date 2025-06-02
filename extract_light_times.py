#! /home/lapishla/miniconda3/envs/openCV/bin/python3
import cv2
import numpy as np
import pandas as pd
import os

def main():
    video_path= "/home/lapishla/Desktop/small_test/videos/8.mp4"
    get_events(video_path)

def get_events(video_path):
    # constant values for left and right lights
    height=50
    y=150 - int(height/2)
    width=10  

    # analyze left light
    x=0
    luminosity = measure_luminosity(video_path, x, y, width, height)
    (L_frame, L_state) = analyze_signal(luminosity)

    # analyze right light
    x=500
    luminosity = measure_luminosity(video_path, x, y, width*-1, height)
    (R_frame, R_state)  = analyze_signal(luminosity)

    # Combine into dataframe
    frame = L_frame + R_frame
    state = L_state + R_state
    side = ['L']*len(L_state) + ['R']*len(R_state)

    dict = {'frame':frame, 'state':state, 'side':side}
    table = pd.DataFrame(dict)
    table = table.sort_values(by='frame')
    return table

def measure_luminosity(video_path, x, y, width, height):
    """
    Opens a video file and measures the average luminosity in a rectangular region.
    Args:
        video_path (str): Path to the video file.
        x (int): X-coordinate of starting point in pixels.
        y (int): Y-coordinate of starting point in pixels.
        width (int): Width of the rectangular region (can be negative).
        height (int): Height of the rectangular region (can be negative).
    Returns:
        List of average luminosity values per frame.
    """
    cap = cv2.VideoCapture(video_path)
    avg_luminosity_values = []
    if not cap.isOpened():
        print("Error: Could not open video file.")
        return avg_luminosity_values
    while True:
        ret, frame = cap.read()
        if not ret:
            break  # End of video
        # Convert frame to grayscale for luminosity measurement
        gray_frame = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)
        # Compute min/max bounds, handling negative width/height
        x_min = min(x, x + width)
        x_max = max(x, x + width)
        y_min = min(y, y + height)
        y_max = max(y, y + height)
        # Ensure bounds remain within frame limits
        x_min = max(0, x_min)
        x_max = min(frame.shape[1], x_max)
        y_min = max(0, y_min)
        y_max = min(frame.shape[0], y_max)
        # Extract the pixel region using NumPy slicing
        region = gray_frame[y_min:y_max, x_min:x_max]
        # Compute the average luminosity in the defined area
        avg_luminosity_values.append(np.mean(region))
    cap.release()
    return avg_luminosity_values

def analyze_signal(signal, threshold=0.6, smooth=False, window_size=3, plot=False):
    """
    Analyzes digital signal to extract ON and OFF transition times.

    Parameters:
    signal (list): A list of values representing the digital signal.
    threshold (float): The threshold to reduce noise sensitivity. (range 0-1)
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
    signal = (signal - np.min(signal)) / (np.max(signal) - np.min(signal))

    # Detect transitions
    above_thresh = signal > threshold
    cross_thresh = np.diff(above_thresh)

    # frame index after rising above threshold
    rising = np.flatnonzero(cross_thresh & above_thresh[1:]) + 1 
    # frame index after fallowing below threshold
    falling = np.flatnonzero(cross_thresh & ~above_thresh[1:]) + 1 

    if plot:
        plot_signal(signal, rising, falling)


    state = [1] * len(rising) + [0] * len(falling)
    frame_number = rising.tolist() + falling.tolist()
    return (frame_number, state)

def plot_signal(signal, rising, falling, xlim=None):
    import matplotlib.pyplot as plt
    plt.figure(figsize=(10, 6))
    x = list(range(len(signal)))
    plt.scatter(x, signal, marker='.')
    plt.xlabel('Frame #')
    plt.ylabel('Luminosity')

    # Mark transitions
    y = 1.1 * np.ones(np.shape(rising))
    plt.scatter(rising, y, color='green')
    y = -.1 * np.ones(np.shape(falling))
    plt.scatter(falling, y, color='red')

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
    main()