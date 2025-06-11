clear
mat_path = "/home/lapishla/Desktop/pv_videos/trials_no_spikes.mat";
load(mat_path)
export_path = "/home/lapishla/Desktop/pv_videos/maria_curated.mat";

video_table.manually_curated = cell(height(video_table),1);
for s = 1:height(video_table)
    if ~istable(video_table.trials{s})
        continue
    end
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
pre_time = 2;
post_time = 8;
frame_dur = 1/20;
trial_skips = 2;
input_msg = "Enter: 'd' (drink) or 'f' (fail to drink) " + ...
    "\n or: 's' (speed up) or 'a' (ahhh... slow down) " + ...
    "\n or: just hit enter to replay the video: ";

video = VideoReader(videoFile);
trial_times = trial_frames / video.FrameRate;
did_drink = nan(size(trial_times));

file_cell = strsplit(videoFile, "/");
videoName = string(file_cell{end});
for ind = 1:trial_skips:length(trial_times)
    start = trial_times(ind) - pre_time;
    stop =  trial_times(ind) + post_time;
    figure(1); clf;
    title(videoName + " : trial " + num2str(ind) + ": " + side{ind})
    while true
        play_video(video, start, stop, frame_dur)
        
        user_input = input(input_msg, 's'); % Read input as string
        if strcmp(user_input, 'd')
            did_drink(ind) = true;
            break;
        elseif strcmp(user_input, 'f')
            did_drink(ind) = false;
            break;
        elseif strcmp(user_input, 's')
            frame_dur = frame_dur / 1.5;
        elseif strcmp(user_input, 'a')
            frame_dur = frame_dur * 1.5;
        end
    end
end
end

function play_video(video, start, stop, frame_dur)
hAxes = axes;
hImg = imshow(zeros(video.Height, video.Width, 3), 'Parent', hAxes);
video.CurrentTime = start; 
while hasFrame(video) && video.CurrentTime < stop
    frame = readFrame(video);
    set(hImg, 'CData', frame);
    drawnow;
    pause(frame_dur);
end
end






