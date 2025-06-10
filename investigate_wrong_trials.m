clear
mat_path = "/home/lapishla/Desktop/pv_videos/analyzed_trials.mat";
load(mat_path)
%%
session = 6;
trial_num = 46;

trials = video_table.trials{session};
tracking = video_table.tracking{session};
trials = add_video_frame_to_trials(trials, tracking);
video_path = video_table.cropped_video{session};

play_trial(video_path, trials(trial_num,:), tracking, "nose", 25)

function trials = add_video_frame_to_trials(trials, tracking)
[~, closest_ind] = min(abs(trials.time' - tracking.oe_times));
trials.frame =  tracking.frame(closest_ind);
end

function  play_trial(video_path, trial, tracking, bodypart, distance_thresh)
pre_time = 1;
post_time = 8;
target_frame_duration = 1 / 10;

video = VideoReader(video_path);

frame_start = trial.frame - (pre_time*video.FrameRate);
frame_stop = trial.frame + (post_time*video.FrameRate);
frames = frame_start:frame_stop;
tracking = tracking(frames, :);

x = table2array(tracking(:, bodypart + "_x"));
y = table2array(tracking(:, bodypart + "_y"));
l = table2array(tracking(:, bodypart + "_likelihood"));

[circle_x,circle_y] = circle(trial.sipper_xy(1),trial.sipper_xy(2),distance_thresh);


video.CurrentTime = frame_start / video.FrameRate; 
xticks = 1:500;
yticks = 1:300;
figure(1); clf; hold on;

hAxes = axes;
hImg = imshow(zeros(video.Height, video.Width, 3), 'Parent', hAxes,  'XData', xticks, 'YData', yticks);
hold on
cmap = colormap(gca,"jet");
clim([0,1])
c = colorbar;
c.Label.String = 'Likelihood';

colors = cmap(round(l * size(cmap, 1)), :);


plot(circle_x,circle_y, 'r',  'Parent', hAxes)
for f = 1:length(frames)
    tic
    frame = readFrame(video);
    % imshow(frame, 'XData', xticks, 'YData', yticks);
    set(hImg, 'CData', frame);
    drawnow;
    hold on
    scatter(x(f),y(f),15, colors(f,:), '+')
    elapsed = toc;
    if elapsed < target_frame_duration
        pause(target_frame_duration-elapsed)
    end
end
end

function [x,y] = circle(x,y,r)
    n=20;
    th = linspace(0, 2*pi , n);
    x = r * cos(th) + x;
    y = r * sin(th) + y;
end




