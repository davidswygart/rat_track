mat_path = "/home/lapishla/Desktop/pv_videos/analyzed_trials.mat";
load(mat_path)
export_path = "/home/lapishla/Desktop/pv_videos/manually_curated.mat";

for s = 1:height(video_table)
    trial_time = video_table.trials{s}.time;
    sync = video_table.tracking{s}(:,["frame","oe_times"]);
    trial_frames = convert_oe_time_to_frame(trial_time, sync);
    video = video_table.cropped_video{s};
    side =  string(video_table.trials{s}.side);
    did_drink = play_all_trials(video, trial_frames, side);
    video_table.manually_curated(s) = {did_drink};
    save(export_path, "video_table")
end

%% Functions
function frames = convert_oe_time_to_frame(oe_time, sync)
frames=nan(size(oe_time));
for ind = 1:length(oe_time)
    [~,closest_ind] = min(abs(oe_time(ind) - sync.oe_times));
    frames(ind) = sync.frame(closest_ind);
end
end

function did_drink = play_all_trials(videoFile, trial_frames, side)
pre_time = 4;
post_time = 8;

video = VideoReader(videoFile);
trial_times = trial_frames / video.FrameRate;
did_drink = nan(size(trial_times));

file_cell = strsplit(videoFile, "/");
videoName = string(file_cell{end});
for ind = 1:length(trial_times)
    start = trial_times(ind) - pre_time;
    stop =  trial_times(ind) + post_time;
    figure(1); clf;
    title(videoName + " : trial " + num2str(ind) + ": " + side{ind})
    while true
        play_video(video, start, stop)
        user_input = input('Enter d (drink) or f (fail to drink) or any other key to replay the video: ', 's'); % Read input as string
        if strcmp(user_input, 'd')
            did_drink(ind) = true;
            break;
        elseif strcmp(user_input, 'f')
            did_drink(ind) = false;
            break;
        end
    end
end
end

function play_video(video, start, stop)
hAxes = axes;
hImg = imshow(zeros(video.Height, video.Width, 3), 'Parent', hAxes);
video.CurrentTime = start; 
while hasFrame(video) && video.CurrentTime < stop
    frame = readFrame(video);
    set(hImg, 'CData', frame);
    drawnow;
    pause(1/50);
end
end






