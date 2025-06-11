mat_file = "/home/lapishla/Desktop/pv_videos/analyzed_trials.mat";
load(mat_file)

figure(1); clf; hold on;
[sipper_time, was_drinking] = calc_time_at_sipper(video_table, "nose", 25);

figure(11); clf; hold on;
plot_presence_thresh_TPR_TNR(sipper_time, was_drinking)


figure(2); clf; hold on;
calc_time_at_sipper(video_table, "probe", 50);

figure(3); clf; hold on;
calc_time_at_sipper(video_table, "mid_back", 150);

%% functions
function [sipper_time, was_drinking] = calc_time_at_sipper(video_table, bodypart, threshold)
pre_time = 0;
post_time = 8;

was_drinking = nan(48,height(video_table));
sipper_time = nan(48,height(video_table));

for s = 1:height(video_table)
    was_drinking(:,s) = video_table.manually_curated{s};

    trials = video_table.trials{s};
    tracking = video_table.tracking{s};
    for t = 1:height(trials)
        start = trials.time(t)-pre_time;
        stop = trials.time(t)+post_time;

        sub_track = tracking(tracking.oe_times > start & tracking.oe_times < stop, :);
        sipper_xy = trials.sipper_xy(t,:);

        dist = calc_dist(sub_track, bodypart, sipper_xy);
        sipper_time(t,s) = mean(dist < threshold);
    end
end
was_drinking = logical(was_drinking);

title(bodypart)
xlabel('time at sipper (proportion of 8s window)')
ylabel('counts')

edges = linspace(0,1,20);
histogram(sipper_time(was_drinking), edges);
histogram(sipper_time(~was_drinking), edges);
legend("drinking trial", "not drinking trial")


end


function dist = calc_dist(track, bodypart, sipper)
tx = table2array(track(:, bodypart + "_x"));
ty = table2array(track(:, bodypart + "_y"));
sx = sipper(1);
sy = sipper(2);

dist = sqrt( (tx-sx).^2 + (ty-sy).^2 );
end


function plot_presence_thresh_TPR_TNR(sipper_time, was_drinking)

threshs = linspace(0,1,100);
correct = nan(size(threshs));
true_positive_rate = nan(size(threshs));
true_negative_rate = nan(size(threshs));
for ind = 1:length(threshs)
    prediction = sipper_time>threshs(ind);
    [c, sen, spec] = calc_performance(was_drinking, prediction);
    correct(ind) = c;
    true_positive_rate(ind) = sen;
    true_negative_rate(ind) = spec;
end

plot(threshs, correct)
plot(threshs, true_positive_rate)
plot(threshs, true_negative_rate)
legend('Correct', 'Sensitivity', 'Specificity')

xlabel('presence threshold')
ylabel('performance')
end

function [correct, sensitivity, specificity] = calc_performance(truth, prediction)
true_positives = sum(truth & prediction, "all");
sensitivity = true_positives / sum(truth, "all");

true_negatives = sum(~truth & ~prediction, 'all');
specificity = true_negatives / sum(~truth, 'all');

correct = mean(truth == prediction, 'all');
end