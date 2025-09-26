% create sync file for each video listed in videos.csv
% sync file is csv with times frame and oe

job_folder = pwd;
video_table = load_video_csv(job_folder);

sync_dir = [job_folder filesep 'sync_times'];
[~,~] = mkdir(sync_dir);

for ind = 1:height(video_table)
    id = video_table.id{ind};
    fprintf("processing %s \n", id)

    % load oe events
    try
        oe = load_oe_events(video_table.oe_export_folder{ind});
    catch
        warning("error loading OE events for %s: skipping",  video_table.id{ind})
        continue
    end

    % load video
    video_path=[job_folder filesep 'videos' filesep id '.mp4'];
    vidObj = VideoReader(video_path);

    % get frame mask for left and right lights
    fprintf("Gettings masks for %s \n", id)
    poi = load_poi(job_folder,id);
    masks = cell(2,1);
    masks{1} = get_mask(vidObj, poi{{'light_left'},:});
    masks{2} = get_mask(vidObj, poi{{'light_right'},:});

    % measure luminance for left and right lights and get frame times
    fprintf("Measuring luminosity for %s \n", id)
    [luminosity, frame_time] = measure_luminosity(vidObj, masks);

    %% left side Syncing
    [on, off] = get_light_on_off(luminosity(:,1));
    fprintf("Left side: %i/%i luminance on/off events \n", length(on), length(off))

    % left ON
    [L_on, msg, err]  = syncable(frame_time(on), oe.timestamp(oe.line==2 & oe.state==0));

    % left OFF
    [L_off, msg, err]  = syncable(frame_time(off), oe.timestamp(oe.line==2 & oe.state==1));

    %% right side Syncing
    [on, off] = get_light_on_off(luminosity(:,2));
    fprintf("Right side: %i/%i luminance on/off events \n", length(on), length(off))

    % right on
    [R_on, msg, err]  = syncable(frame_time(on), oe.timestamp(oe.line==1 & oe.state==0));

    % right off
    [R_off, msg, err]  = syncable(frame_time(off), oe.timestamp(oe.line==1 & oe.state==1));

    %% Interp OE times from all available synced frame times
    sync_times = cat(1, L_on,L_off,R_on,R_off);
    fprintf("total syncable times: %i \n", size(sync_times, 1))

    if size(sync_times, 1) < 2
        warning("unable to sync " + id)
        continue
    end

    sync_table = table();
    sync_table.video = frame_time;

    sync_table.oe = interp_frame_times(sync_times, frame_time);

    sync_file = [sync_dir filesep id '_sync.csv'];
    fprintf("saving to %s \n", sync_file)
    writetable(sync_table, sync_file)
end

function mask = get_mask(vidObj, xy, box_scale)
    if nargin<3
        box_scale = [0.03, 0.1]; % width and height of bounding box as fraction of image size
    end

    mask = zeros(vidObj.Width, vidObj.Height);
    mask_sz = size(mask);

    box_size = box_scale .* mask_sz;
    start = round(xy-box_size/2);
    stop = round(xy+box_size/2);

    start(start<1) = 1;
    oversized = stop>mask_sz;
    stop(oversized)= mask_sz(oversized);

    mask(start(1):stop(1),start(2):stop(2)) = ones(stop-start+1);
    mask = logical(mask);
end

function [synced, completion_msg, rmse]= syncable(f,t)
    f = sort(f);
    t = sort(t);

    if isempty(f)
        completion_msg = sprintf("No frametimes to sync");
        synced = [];
        rmse = inf;
        return
    end

    error_threshold = 0.1;
    if length(f) == length(t)
        norm_rmse = get_diff_error(f, t);
        if norm_rmse < error_threshold
            synced = [f,t];
            completion_msg = sprintf("Completed successfully");
            rmse = norm_rmse;
            return
        else
            completion_msg = sprintf("Normalized RMSE of" + ...
                " time differentials (%d) above" + ...
                " error threshold (%d)",norm_rmse, error_threshold);
            synced = [];
            rmse = norm_rmse;
            return
        end
    else
        % figure out which is shorter; OE or video
        [min_length, shorter_ind] = min([length(t), length(f)]);
        rec_type = ["OE", "video"];
        shorter_type = rec_type(shorter_ind);
        
        % try trimming off the end of the longer recording
        trim_t_end = t(1:min_length);
        trim_f_end = f(1:min_length);
        norm_rmse_trim_end = get_diff_error(trim_t_end, trim_f_end);

        % try trimming off the start of the longer recording
        trim_t_start = t(end-min_length+1:end);
        trim_f_start = f(end-min_length+1:end);
        norm_rmse_trim_start = get_diff_error(trim_t_start, trim_f_start);

        % pick the trimming strategy that yeilded the lowest error
        [min_rmse, best_ind] = min([norm_rmse_trim_end, norm_rmse_trim_start]);
        strategies = ["trimming end", "trimming start"];
        best_strategy = strategies(best_ind);
        both_synced = {[trim_f_end,trim_t_end], [trim_f_start,trim_t_start]};
        best_synced = both_synced{best_ind};

        % check if the best strategy yeilded acceptably low error
        if min_rmse < error_threshold
            completion_msg = sprintf("Hacky success. %s had fewer events than expected." + ...
                " %s of longer recording resulted in acceptable rmse (%d)", ...
                shorter_type, best_strategy, min_rmse);
            synced = best_synced;
            rmse = min_rmse;
            return
        else
            completion_msg = sprintf("Failure. %s had fewer events than expected." + ...
                " %s of longer recording still resulted in unacceptable rmse (%d)", ...
                shorter_type, best_strategy, min_rmse);
            synced = [];
            rmse = min_rmse;
            return
        end
    end



end
function [luminosity, time] = measure_luminosity(vidObj, masks)
    num_frames = round(vidObj.Duration * vidObj.FrameRate * 1.1); % initial estimate of number of frames + 10% for preallocating arrays
    luminosity = zeros(num_frames, length(masks));
    time=zeros(num_frames,1);

    cur_frame = 0;
    while hasFrame(vidObj)
        frame = rgb2gray(readFrame(vidObj))';
        cur_frame = cur_frame+1;
        for i=1:length(masks)
            luminosity(cur_frame,i) = sum(frame(masks{i}));
        end
        time(cur_frame) = vidObj.CurrentTime;
    end
    luminosity = luminosity(1:cur_frame,:);
    time = time(1:cur_frame);
end
function [rising, falling] = get_light_on_off(signal, threshold, smooth, window_size)
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
end
function all_e = interp_frame_times(sync_times, all_f)
    fprintf("Interpolating all %i frames \n", length(all_f))
    f = sync_times(:,1);
    e = sync_times(:,2);
    [f,~,idx] = unique(f,'stable'); % check for duplicate frame times
    e = accumarray(idx,e,[],@mean); % use mean oe time for duplicate frame times
    all_e = interp1(f,e,all_f, 'linear','extrap');
end

function norm_rmse = get_diff_error(f, t)
    % zero shift
    % f = f - f(1); % not needed if using real seconds
    % t = t - t(1); % not needed if using real seconds

    % convert f to t time
    % f = f * t(end) / f(end); % not needed if using real seconds

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

