function oe_sync = load_oe_video_sync(job_folder,id)
    file = [job_folder filesep 'oe_sync' filesep id '_oe_sync.csv'];
    oe_sync = readtable(file, 'Delimiter', ',');
end