function oe_sync = load_oe_video_sync(job_folder,id)
    file = [job_folder filesep 'sync_times' filesep id '_sync.csv'];
    oe_sync = readtable(file, 'Delimiter', ',');
end