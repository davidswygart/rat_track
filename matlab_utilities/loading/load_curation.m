function [did_drink, path] = load_curation(job_folder, id)
    curation_folder = [job_folder filesep 'manually_curated' filesep];
    

    path = [curation_folder, id, '.csv'];
    if exist(path,"file")
        did_drink = readtable(path, 'Delimiter', ',');
    else
        [~,~] = mkdir(curation_folder);
        did_drink = [];
    end
end