function [did_drink, path] = load_curation(job_folder, id)
    curation_folder = [job_folder filesep 'manually_curated' filesep];
    

    path = [curation_folder, id, '.csv'];
    if exist(path,"file")
        did_drink = readmatrix(path);
    else
        [~,~] = mkdir(curation_folder);
        did_drink = [];
    end
end