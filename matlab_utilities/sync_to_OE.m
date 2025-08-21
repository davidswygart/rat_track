% create sync file for each video listed in videos.csv
% sync file is csv with times frame and oe

job_folder = pwd;
csv_path = [job_folder filesep 'videos.csv'];
video_table = readtable(csv_path, 'Delimiter', ',');

sync_dir = [job_folder filesep 'oe_sync'];
[~,~] = mkdir(sync_dir);

for ind = 1:height(video_table)
    id = video_table.id{ind};
    video_path=[job_folder filesep 'videos' filesep id '.mp4'];

    poi_path = [job_folder filesep 'poi' filesep id '_poi.csv'];
    poi = readtable(poi_path,  'Delimiter', ',', 'ReadRowNames', true);

    oe = load([video_table.oe_export_folder{ind} filesep 'events.mat']);
    oe = struct2table(oe.data);
    
    oe_L = oe(oe.line == 2, :);
    sync_L = sync_side(video_path, poi{{'light_left'},:}, oe_L);
    oe_R = oe(oe.line == 1, :);
    sync_R = sync_side(video_path, poi{{'light_right'},:}, oe_R);
    sync_events = cat(1,sync_R,sync_L);
    if isempty(sync_events)
        warning("unable to sync " + video_path)
        continue
    end

    sync_frames = interp_frame_times(sync_events, video_path);
    sync_file = [sync_dir filesep id '_oe_sync.csv'];
    writetable(sync_frames, sync_file)

    disp("finished")
end

function synced = sync_side(video_path, light_xy, oe_events)
    luminosity = measure_luminosity(video_path, light_xy);
    light_events = get_light_on_off_times(luminosity);

    % are ON events syncable?
    f = light_events.frame(light_events.state==1);
    t = oe_events.timestamp(oe_events.state==0);
    synced_on = syncable(f,t);

    % are ON events syncable?
    f = light_events.frame(light_events.state==0);
    t = oe_events.timestamp(oe_events.state==1);
    synced_off = syncable(f,t);

    both = [synced_on;synced_off];
    synced = table();
    if ~isempty(both)
        synced.frame = both(:,1);
        synced.time = both(:,2);
    end
end
function synced = syncable(f,t)
    if length(f) ~= length(t)
        synced = [];
        return
    end
    f = sort(f);
    t = sort(t);
    norm_rmse = get_diff_error(f, t);
    if norm_rmse > 0.1
        synced = [];
        return
    end

    synced = [f,t];
end
function luminosity = measure_luminosity(video_path, point)
    disp("measuring luminosity for " + video_path)
    vidObj = VideoReader(video_path);
    frame_width = vidObj.Width;
    frame_height = vidObj.Height;
    width = 0.03 * frame_width;
    height = 0.1 * frame_height;
    x_min = max(floor(point(1) - width/2), 1);
    x_max = min(floor(point(1) + width/2), frame_width);
    y_min = max(floor(point(2) - height/2), 1);
    y_max = min(floor(point(2) + height/2), frame_height);

    luminosity = nan(vidObj.NumFrames, 1);
    for k = 1:vidObj.NumFrames
        frame = read(vidObj, k);
        gray_frame = rgb2gray(frame);
        luminosity(k) = sum(gray_frame(y_min:y_max, x_min:x_max), 'all');

        % figure(1); clf; hold on;
        % imshow(gray_frame)
        % plot([x_min,x_max,x_max,x_min,x_min], [y_max,y_max,y_min,y_min,y_max])
    end
end
function light_events = get_light_on_off_times(signal, threshold, smooth, window_size)
    if nargin < 2, threshold = 3; end
    if nargin < 3, smooth = true; end
    if nargin < 4, window_size = 3; end

    if smooth
        signal = movmean(signal, window_size);
    end
    signal = zscore(signal);
    threshold = median(signal) + threshold;

    figure(1); clf; hold on;
    plot(signal)
    yline(threshold, '--')
    xlabel('frames')
    ylabel('luminosity (zscore)')

    above_thresh = signal > threshold;
    cross_thresh = diff(above_thresh);
    rising = find(cross_thresh == 1);
    falling = find(cross_thresh == -1);

    state = [ones(length(rising), 1); zeros(length(falling), 1)];
    frame = [rising; falling];
    light_events = table(frame,state);
end
function synced = interp_frame_times(sync_events, video_path)
f = sync_events.frame;
t = sync_events.time;
[f,~,idx] = unique(f,'stable'); % check for duplicate frame values
t = accumarray(idx,t,[],@mean); % use mean t for duplicate frame values

vidObj = VideoReader(video_path);
frame = 1:vidObj.NumFrames;

time = interp1(f,t,frame, 'linear','extrap');
synced = table();
synced.frame = frame';
synced.time = time';
end

function norm_rmse = get_diff_error(f, t)
    % zero shift
    f = f - f(1);
    t = t - t(1);

    % convert f to t time
    f = f * t(end) / f(end);

    % get the signal differences
    f_diff = diff(f);
    t_diff = diff(t);
    
    figure(1); clf; hold on;
    plot(f_diff)
    plot(t_diff)

    ylabel('time since last event')
    xlabel('event number')
    legend('video', 'ephys')

    rmse = sqrt(mean((f_diff-t_diff).^2));
    norm_rmse = rmse / mean([f_diff; t_diff]);
end

