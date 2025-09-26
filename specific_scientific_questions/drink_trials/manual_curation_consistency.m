%% find matching curated files
main_folder = "manually_curated";
madison_folder = "manually_curated_madison";

main_files = get_filenames(main_folder);
madison_files = get_filenames(madison_folder);
common_files = intersect(main_files, madison_files);

%% load data into single table
main = table();
madison = table();
for ind=1:length(common_files)
    main = cat(1, main, readtable(maria_folder + filesep + common_files(ind)));
    madison = cat(1, madison, readtable(madison_folder + filesep + common_files(ind)));
end
%% Determine consistency
disp("Consistency to absolute ground truth knowledge (Madison)")
names = unique(main.curator);
for i=1:length(names)
    is_t = strcmp(main.curator, names(i));
    match = main.drank(is_t) == madison.drank(is_t);
    fprintf(" \n%s: %.2f consistency, N=%d",names{i}, sum(match) / sum(is_t), sum(is_t))
end
%% functions
function filenames = get_filenames(folder)
    files = dir(folder + filesep + "*csv");
    files = struct2table(files);
    filenames = string(files.name);
end

