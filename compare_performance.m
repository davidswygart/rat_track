% mat_file = "/home/lapishla/Desktop/pv_videos/manually_curated.mat";
mat_file = "/home/lapishla/Desktop/pv_videos/analyzed_trials.mat";
load(mat_file)

has_manual = ~cellfun(@isempty, video_table.manually_curated);
video_table = video_table(has_manual, :);

perf_nose = nan(height(video_table), 2); % columns: sensitivity, specificity
perf_probe = perf_nose;
perf_best = perf_nose;
perf_back = perf_nose;

for ind = 1:height(video_table)
   
    truth = video_table.manually_curated{ind};

    % nose
    nose_p = video_table.trials{ind}.nose_did_drink;
    perf_nose(ind,:) = calc_performance(truth, nose_p);

    % probe
    probe_p = video_table.trials{ind}.probe_did_drink;
    perf_probe(ind,:) = calc_performance(truth, probe_p);

    % best
    nose_conf = video_table.trials{ind}.nose_likelihood;
    probe_conf = video_table.trials{ind}.probe_likelihood;
    use_probe = probe_conf > nose_conf;
    fprintf('\n probe best %f', mean(use_probe))
    
    best_p = nose_p;
    best_p(use_probe) = probe_p(use_probe);
    perf_best(ind,:) = calc_performance(truth, best_p);

    % back
    back_p = video_table.trials{ind}.back_did_drink;
    perf_back(ind,:) = calc_performance(truth, back_p);
end

%% plot sensitivity (true-positive-rate)
figure(4); clf;
names = {'nose','probe','best','back'};
t = 1;
data = {perf_nose(:,t), perf_probe(:,t), perf_best(:,t),  perf_back(:,t)};
plot_bar_with_data(names, data)
title('True positive rate (sensitivity)')

figure(5); clf;
names = {'nose','probe','best','back'};
t = 2;
data = {perf_nose(:,t), perf_probe(:,t), perf_best(:,t),  perf_back(:,t)};
plot_bar_with_data(names, data)
title('True negative rate (specificity)')
%% functions
function performance = calc_performance(truth, prediction)
true_positives = sum(truth & prediction);
sensitivity = true_positives / sum(truth);

true_negatives = sum(~truth & ~prediction);
specificity = true_negatives / sum(~truth);

correct = truth == prediction;

performance = [sensitivity; specificity];
end

function plot_bar_with_data(categories, data)
% plotBarWithPoints - Plots a bar graph with categorical labels and overlays individual data points.
%
% Syntax: plotBarWithPoints(categories, data)
%
% Inputs:
%   categories - Cell array of category labels (e.g., {'A', 'B', 'C'})
%   data       - Cell array where each cell contains a vector of data points for the corresponding category

    % Validate inputs
    if length(categories) ~= length(data)
        error('Number of categories must match number of data groups.');
    end

    % Calculate means for each category
    means = cellfun(@mean, data);

    % Create categorical array for x-axis
    catLabels = categorical(categories);
    catLabels = reordercats(catLabels, categories);

    % Plot bar graph
    
    bar(catLabels, means, 'FaceColor', [0.2 0.6 0.8]);
    hold on;

    % Overlay individual data points
    for i = 1:length(data)
        x = repmat(i, size(data{i}));
        jitter = (rand(size(data{i})) - 0.5) * 0.2; % Add jitter for visibility
        scatter(x + jitter, data{i}, 50, 'k', 'filled', 'MarkerFaceAlpha', 0.6);
    end
    grid on;

    ylabel('Performance');
end
