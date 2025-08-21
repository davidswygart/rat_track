%% load matching curated files
maria_folder = "manually_curated_maria";
madison_folder = "manually_curated_madison";

maria_files = get_filenames(maria_folder);
madison_files = get_filenames(madison_folder);
common_files = intersect(maria_files, madison_files);

matches = nan(length(common_files),1);
total = matches;
for ind=1:length(common_files)
    maria = readmatrix(maria_folder + filesep + common_files(ind));
    madison = readmatrix(madison_folder + filesep + common_files(ind));

    is_match = maria == madison;
    not_nan = ~isnan(maria) & ~isnan(madison);
    
    matches(ind) = sum(is_match & not_nan);
    total(ind) = sum(not_nan);
    fprintf(" \n %d of %d matching for %s", matches(ind),total(ind),common_files(ind))
end
fprintf(" \n %.2f total consistency, N=%d", sum(matches) / sum(total), sum(total))

%% functions
function filenames = get_filenames(folder)
    files = dir(folder + filesep + "*csv");
    files = struct2table(files);
    filenames = string(files.name);
end

