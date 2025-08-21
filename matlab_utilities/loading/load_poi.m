function poi = load_poi(job_folder, id)
    file = [job_folder filesep 'poi' filesep  id '_poi.csv'];
    poi = readtable(file,  'Delimiter', ',', 'ReadRowNames', true);
end
