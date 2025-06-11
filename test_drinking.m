clear
csv_path = "/home/lapishla/Desktop/pv_videos/Anymaze_of_interest.csv.mat";
export_path = "/home/lapishla/Desktop/pv_videos/trials.mat";
load(csv_path);

% convert_to_cropped_units(video_table) % TODO: Add this at the cropping step so this isn't needed
video_table(cellfun(@isempty, video_table.tracking), :) = []; % remove rows for which syncing failed (missing tracking info)
video_table.trials = cell(height(video_table),1);
for s = 1:height(video_table)
    tracking = video_table.tracking{s};
    oe_events = video_table.oe_events{s};

    if isempty(oe_events) | ~istable(tracking)
        % warning('skipping: missing OE events or tracking data')
        continue
    end


    sipper_xy = parse_pair_points(video_table.sipper_points{s});
    sipper_xy_left = sipper_xy(1,:);
    sipper_xy_right = sipper_xy(2,:);
    try
        video_table.trials{s} = test_if_drank_single(tracking, oe_events, sipper_xy_left, sipper_xy_right);
    catch
        warning('trial analysis failed at ind =  %d', s)
    end
end
% save(export_path, "video_table")

%% Functions
function analyzed_trials = test_if_drank_single(tracking, oe_events, sipper_xy_left, sipper_xy_right)
trials = get_trials(oe_events, sipper_xy_left, sipper_xy_right);
trials = sortrows(trials,"time","ascend");
for t = 1:size(trials,1)
    analyzed_trials(t,:) = test_if_drinking_trial(trials(t,:), tracking);
end
end

function trial = test_if_drinking_trial(trial, tracking)
pre_time = 0;
post_time = 8;

t = tracking.oe_times;
is_trial = t>(trial.time-pre_time) & t<(trial.time+post_time);
tracking = tracking(is_trial, :);

% Nose: check if drank
thresh = 25;
x = tracking.nose_x;
y = tracking.nose_y;
trial.nose_did_drink = test_near_sipper(x,y, trial.sipper_xy, thresh);
trial.nose_likelihood = mean(tracking.nose_likelihood);

% figure(1);clf;hold on;
% title('nose')
% plot_position(x,y,tracking.nose_likelihood, trial.sipper_xy)

% Probe: check if drank
thresh = 50;
x = tracking.probe_x;
y = tracking.probe_y;
trial.probe_did_drink = test_near_sipper(x,y, trial.sipper_xy, thresh);
trial.probe_likelihood = mean(tracking.probe_likelihood);

% figure(2);clf;hold on;
% title('probe')
% plot_position(x,y,tracking.probe_likelihood, trial.sipper_xy)

% mid_back: check if drank
thresh = 150;
x = tracking.mid_back_x;
y = tracking.mid_back_y;
trial.back_did_drink = test_near_sipper(x,y, trial.sipper_xy, thresh);
trial.back_likelihood = mean(tracking.mid_back_likelihood);

% figure(3);clf;hold on;
% title('back')
% plot_position(x,y,tracking.mid_back_likelihood, trial.sipper_xy)
end

function is_near = test_near_sipper(tx, ty, sipper, thresh)
sx = sipper(1);
sy = sipper(2);

distance = sqrt( (tx-sx).^2 + (ty-sy).^2 );
is_near = any(distance<thresh);
end

function plot_position(x,y,l, sipper_xy)
cmap = colormap(gca,"jet");
clim([0,1])
c = colorbar;
c.Label.String = 'Likelihood';
% plot(x,y, 'k')
% scatter(x,y, 40, l, 'filled')
scatter(sipper_xy(1), sipper_xy(2), 1000,'+k' )
xlim([0,500])
ylim([0,300])
for i=1:length(x)-1
    inds = i:i+1;
    c_ind = round(l(i) * size(cmap, 1));
    c = cmap(c_ind, :);
    plot(x(inds), y(inds), 'Color',c, 'LineWidth',5)
    pause(1/15)
end
end

function pass = test_sufficient_tracking_confidence(likelihood,likelihood_thresh, prescence_thresh)
confident_points = likelihood > likelihood_thresh;
pass = mean(confident_points) > prescence_thresh;

plot_uncertainty_cdf(likelihood,likelihood_thresh, prescence_thresh)
end

function plot_uncertainty_cdf(likelihood,likelihood_thresh, prescence_thresh)
uncertainty = 1 - likelihood;
uncertainty_thresh = 1 - likelihood_thresh;

cdfplot(uncertainty)
yline(prescence_thresh, '--')
xline(uncertainty_thresh, '--')
xlim([0,1])
ylim([0,1])

xlabel('Uncertainty (1-likelihood)')
ylabel('Cumulative robability')
text(0,prescence_thresh,'Prescence Theshold', 'VerticalAlignment','bottom','HorizontalAlignment', 'left')
text(uncertainty_thresh,0,'1 - Likelihood Threhsold', 'Rotation', 270, 'VerticalAlignment','bottom','HorizontalAlignment', 'right')
end

function trials = get_trials(oe_events, sipper_xy_left, sipper_xy_right)
ON_state = 0;
left_sipper_line = 4;
L_times= get_trial_start(oe_events, left_sipper_line, ON_state);
right_sipper_line = 3;
R_times= get_trial_start(oe_events, right_sipper_line, ON_state);
n_l = length(L_times);
n_r = length(R_times);
trials = table();
trials.time = [L_times; R_times];
trials.side = [repmat('L', n_l,1); repmat('R', n_r,1)];
trials.sipper_xy = [repmat(sipper_xy_left, n_l,1); repmat(sipper_xy_right, n_r,1)];
end

function times = get_trial_start(oe_events, line, ON_state)
trial_duration_threshold = 6; %Sipper should be out for at least 6 seconds to beconsidered a trial
oe_events = struct2table(oe_events.data);

is_ON = oe_events.state == ON_state;
is_line = oe_events.line == line;
ON_time = oe_events.timestamp(is_ON & is_line);
OFF_time = oe_events.timestamp(~is_ON & is_line);

event_duration = OFF_time - ON_time;
is_trial = event_duration > trial_duration_threshold;
times = ON_time(is_trial);
end

function video_table = convert_to_cropped_units(video_table)
for ind = 1:size(video_table, 1)
    pair_string = video_table.light_points{ind};
    xyxy = str2double(extract(pair_string, digitsPattern)); % TODO: save mat file with numbers so string parsing isn't needed
    xy = reshape(xyxy, [2,2])';

    % This was taked from crop_video.py and converted to Matlab code
    min_x = min(xy(:,1)); 
    max_x = max(xy(:,1));
    width = max_x - min_x;
    height = width*3/5;
    avg_y = fix(mean(xy(:,2))); 
    min_y = fix(avg_y - height/2);
    %
    
    %convert to relative distance accross the image (0-1)
    xy_relative = nan(2);
    xy_relative(:,1) = (xy(:,1) - min_x) / width;
    xy_relative(:,2) = (xy(:,2) - min_y) / height;

    %convert to real pixel coordinates of the cropped video
    new_width = 500;
    new_height = 300;
    xy_new_pixels = nan(2);
    xy_new_pixels(:,1) = xy_relative(:,1) * new_width;
    xy_new_pixels(:,2) = xy_relative(:,2) * new_height;
end
end
%%
function video_table = parse_sipper_points(video_table)
for ind = 1:size(video_table, 1)
    s = video_table.sipper_points{ind};
    xy = parse_pair_points(s);
    video_table.sipper_points{ind} = xy;
end
end

function xy = parse_pair_points(pair_string)
xyxy = str2double(extract(pair_string, digitsPattern)); % TODO: save mat file with numbers so string parsing isn't needed
xy = reshape(xyxy, [2,2])';
end
