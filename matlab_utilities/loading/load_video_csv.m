function video_table = load_video_csv(job_folder)
    csv_path = [job_folder filesep 'videos.csv'];
    video_table = readtable(csv_path, 'Delimiter', ',');
end