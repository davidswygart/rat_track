mat_file = "/home/lapishla/Desktop/pv_videos/analyzed_trials.mat";
load(mat_file)

figure(1); clf; hold on;
calc_all_dists(video_table, "nose");

figure(2); clf; hold on;
calc_all_dists(video_table, "probe");

figure(3); clf; hold on;
calc_all_dists(video_table, "mid_back");

%% functions
function calc_all_dists(video_table, bodypart)

edges = 0:1:500;
dist_drinking = nan(height(video_table), length(edges)-1);
dist_not_drinking = dist_drinking;
for s = 1:height(video_table)
    trials = video_table.trials{s};
    tracking = video_table.tracking{s};
    manual = video_table.manually_curated{s};
    session_dist_drink = [];
    session_dist_not_drink = [];
    for t = 1:height(trials)
        pre_time = 0;
        post_time = 8;

        start = trials.time(t)-pre_time;
        stop = trials.time(t)+post_time;

        sub_track = tracking(tracking.oe_times > start & tracking.oe_times < stop, :);
        sipper_xy = trials.sipper_xy(t,:);

        trial_dist = calc_dist(sub_track, bodypart, sipper_xy);
        if manual(t)
            session_dist_drink = [session_dist_drink; trial_dist];
        else
            session_dist_not_drink = [session_dist_not_drink; trial_dist];
        end
    end
    dist_drinking(s,:) = histcounts(session_dist_drink,edges);
    dist_not_drinking(s,:) =  histcounts(session_dist_not_drink,edges);
end

title(bodypart)
xlabel('distance from sipper (pixels)')
ylabel('counts')

x = edges(1:end-1);
plot(x, mean(dist_drinking), 'k', 'LineWidth',2)
plot(x, mean(dist_not_drinking), 'r', 'LineWidth',2)
% s = 6; % low scorer
% plot(x, dist_drinking(s,:), 'g', 'LineWidth',1)
% plot(x, dist_not_drinking(s,:), 'b', 'LineWidth',1)

legend("drinking", "not drinking")
% histogram(dist)


end


function dist = calc_dist(track, bodypart, sipper)
tx = table2array(track(:, bodypart + "_x"));
ty = table2array(track(:, bodypart + "_y"));
sx = sipper(1);
sy = sipper(2);

dist = sqrt( (tx-sx).^2 + (ty-sy).^2 );
end