#!/home/lapishla/miniconda3/envs/DEEPLABCUT/bin/python3
import deeplabcut
import os
import glob
import sys

def main(job_folder):
    config = "/home/lapishla/Desktop/pv2cap-2-2025-05-28/config.yaml" # TODO make not hard coded. Put model in repository?
    videos = os.path.join(job_folder, "videos")
    destfolder = os.path.join(job_folder, "dlc_results")
    os.makedirs(destfolder, exist_ok=True)

    deeplabcut.analyze_videos(
        config=config,
        videos=videos,
        destfolder=destfolder,
        save_as_csv=True
    )

    deeplabcut.filterpredictions(
        config=config,
        video=videos,
        destfolder=destfolder,
        save_as_csv=True
    )

    deeplabcut.plot_trajectories(
        config=config,
        videos=videos,
        destfolder=destfolder,
        filtered=True,
        pcutoff = None
    )

    deeplabcut.create_labeled_video(
        config=config,
        videos=videos,
        destfolder=destfolder,
        filtered=True,
        trailpoints = 3,
        pcutoff = 0,
        overwrite = True,
        dotsize=1,
        draw_skeleton=True,
    )

    deeplabcut.analyzeskeleton(
        config=config,
        videos=videos,
        destfolder=destfolder,
        save_as_csv=True,
        filtered=True
    )

    organize_results(destfolder)

def organize_results(destfolder):
    move_files_to_subdirectory(destfolder, "labeled_video",".mp4")
    move_files_to_subdirectory(destfolder, "xy_filtered","_filtered.csv")
    move_files_to_subdirectory(destfolder, "skeleton","_skeleton.csv")
    move_files_to_subdirectory(destfolder, "xy_raw",".csv")
    move_files_to_subdirectory(destfolder, "h5",".h5")
    move_files_to_subdirectory(destfolder, "pickle",".pickle")

def move_files_to_subdirectory(current_dir, sub_name, file_end):
    sub_dir = os.path.join(current_dir, sub_name)
    os.makedirs(sub_dir, exist_ok=True)
    for f in glob.glob(os.path.join(current_dir, f"*{file_end}")):
        os.rename(f, os.path.join(sub_dir, os.path.basename(f)))


if __name__ == "__main__":
    job_folder = sys.argv[1]
    main(job_folder)