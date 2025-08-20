

%%
sip_lines = [4,3]; % OE event lines corresponding to L and R sippers
pre_time = 6; %time before sipper (light should start 5s prior)
post_time = 8; %time after sipper (sipper stays out for 8s)

job_folder = pwd;
csv_path = [job_folder filesep 'videos.csv'];
video_table = readtable(csv_path, 'Delimiter', ',');

for ind=1:height(video_table)
    id = video_table.id{ind};

    video_path=[job_folder filesep 'videos' filesep id '.mp4'];

    % load OE events
    oe_events = load_oe_events(video_table.oe_export_folder{ind});
    poi = load_poi(job_folder, id);

    % load tracking (also loads oe time sync)
    tracking = get_all_tracking(job_folder, id);
    [time, is_L] = get_trial_times(oe_events, sip_lines);

    for ind_t = 1:length(time)
        t=time(ind_t);


        pre_light = split_by_time(tracking, [t-6,t-5]); %1s prior to light
        mid_light = split_by_time(tracking, [t-5,t-1]);% 4s of light
        sip_wait = split_by_time(tracking, [t-1,t;]); % 1s waiting period
        trial = split_by_time(tracking, [t-pre_time,t+post_time]);
        
        if is_L(ind_t)
            light = poi{{'light_left'},:};
        else
            light = poi{{'light_right'},:};
        end

        % figure(3); clf; hold on;
        % trial_video(trial,video_path)

        % figure(1); clf; hold on;
        % scatter(light(:,1), light(:,2), 'filled','red')
        % plot_gaze(pre_light, "magenta");
        % plot_gaze(mid_light, "cyan");
        % plot_gaze(sip_wait, "blue");
        % xlim([1,640])
        % ylim([1,480])
        % daspect([1 1 1])
        % title(sprintf("Video: %d \nTrial: %d", ind, ind_t))

        % trial_video(trial_track,light,video_path);

        t_time = trial.time - t;
        gaze_angle = calc_gaze_angle(trial);
        light_angle = calc_angle_to_light(trial, light);
        gaze_diff =  gaze_angle - light_angle;
        gaze_diff = abs(mod(gaze_diff+180,360)-180);


        figure(2); clf; hold on;
        % light rectangle and text
        rectangle(Position=[-5,0,4,180], FaceColor='yellow', EdgeColor='yellow')
        text(-6/2, 178, 'CS+', HorizontalAlignment='center', VerticalAlignment='top')
        % sipper rectangle and text
        color = ones(3,1) * 0.8;
        rectangle(Position=[0,0,8,180], FaceColor=color, EdgeColor=color)
        text(8/2 , 178, 'sipper', HorizontalAlignment='center', VerticalAlignment='top')
        % plot gaze_diff
        plot(t_time, gaze_diff)

        xlabel("time before sipper (s)")
        ylabel("Gaze offset from CS+ (°)")
        ylim([0,180])
        title(sprintf("Video: %d \nTrial: %d", ind, ind_t))

        pause(1);
    end
end
function track = split_by_time(track, tlim)
    is_trial = track.time>tlim(1) & track.time<tlim(2);
    track = track(is_trial,:);
end
function plot_gaze(track, color)
    gaze_angle = calc_gaze_angle(track);
    
    midpoint = calc_head_midpoint(track);

    % scale = abs(diff(gaze_angle)) / 2;
    scale = 30;

    gaze_angle = gaze_angle(1:end-1);
    midpoint=midpoint(1:end-1,:);
    dx = scale .* cosd(gaze_angle);
    dy = scale .* sind(gaze_angle);
    x = midpoint(:,1);
    y = midpoint(:,2);
    h = quiver(x,y,dx,dy,0, Color=color);
    h.LineWidth = 3;
    
end

function trial_video(t,video_path)
    vidObj = VideoReader(video_path);
    time_offset = vidObj.CurrentTime;

    for i = 1:height(t)-1
        vidObj.CurrentTime = (t.frame(i) - 1)/vidObj.FrameRate + time_offset;
        imshow(readFrame(vidObj));
        hold on

        scatter(t.ear_L_x(i),t.ear_L_y(i), '.g')
        scatter(t.ear_R_x(i),t.ear_R_y(i), '.b')
        plot_gaze(t(i:i+1,:), 'red')
        title(sprintf("f: %d", i))
        pause(1/30);
    end
end

function display_frame(video_path, frame)
    vidObj = VideoReader(video_path);
    time_offset = vidObj.CurrentTime;

    vidObj.CurrentTime = (frame - 1)/vidObj.FrameRate + time_offset;
    frame = readFrame(vidObj);
    imshow(frame);
end

function poi = load_poi(job_folder, id)
    file = [job_folder filesep 'poi' filesep  id '_poi.csv'];

    poi = readtable(file,  'Delimiter', ',', 'ReadRowNames', true);
end

function [time, is_L] = get_trial_times(oe_events, sip_lines)
    sip_dur_threshold = 2; % non-trial sipper pulses for 0.5s, trial sipper pulses for 8s
    
    % get onset times for left and right sipper, filter by event duration
    [L_on, L_dur] = get_event_times(oe_events, sip_lines(1));
    L_on = L_on(L_dur>sip_dur_threshold);
    [R_on, R_dur] = get_event_times(oe_events, sip_lines(2));
    R_on = R_on(R_dur>sip_dur_threshold);

    % merge left and right trial times
    time = [L_on; R_on];
    is_L = zeros(size(time));
    is_L(1:length(L_on)) = 1;

    % sort by time
    [time, sort_ind] = sort(time);
    is_L = is_L(sort_ind);
end

function [on, dur] = get_event_times(oe_events, line)
    e = oe_events(oe_events.line==line, :);
    % assumes first event state is ON, and each ON is followed by OFF
    if length(unique(e.state)) > 2
        error('more than 2 OE event states')
    end
    if any(diff(e.state) == 0)
        error('unexpected repeated OE event state') 
    end

    on = e.timestamp(1:2:end);
    off = e.timestamp(2:2:end);
    if length(on) ~= length(off)
        error('unequal number of ON and OFF OE event')
    end
    
    dur = off-on;
end

function tracking = get_all_tracking(job_folder, id)
    dlc_results = [job_folder filesep 'dlc_results' filesep];

    % load filtered xy position
    file = [dlc_results 'xy_filtered' filesep  id '*_filtered.csv'];
    tracking = load_tracking_csv(file, [2,3]);
   
    % load skeleton
    file = [dlc_results 'skeleton' filesep  id '*_skeleton.csv'];
    skeleton = load_tracking_csv(file, [1,2]);
    
    % merge skeleton and xy position into a single table
    skeleton = removevars(skeleton, 'frame'); % remove duplicate "frame" column
    tracking = cat(2, tracking, skeleton);

    % load frame to OE time syncing data
    file = [job_folder filesep 'oe_sync' filesep id '_oe_sync.csv'];
    oe_sync = readtable(file, 'Delimiter', ',');
    tracking.time = oe_sync.time;
end

function tracking = load_tracking_csv(csv_path, header_lines)
    % allow for wildcards
    d = dir(csv_path);
    csv_path = [d.folder filesep d.name];

    % load header
    header_rows = cell(max(header_lines), 1);


    fid = fopen(csv_path, 'r');
    for i=1:max(header_lines)
        header_rows{i} = strsplit(fgetl(fid), ',');
    end
    fclose(fid); % Close the file

    header_rows = header_rows(header_lines);
    header = string(header_rows{1}) + "_" +  string(header_rows{2});
    header(1) = "frame";

    % load the data
    tracking = readtable(csv_path, Delimiter=',', NumHeaderLines=max(header_lines));
    tracking.Properties.VariableNames = header;
end

function oe_events = load_oe_events(oe_export_folder)
    oe = load([oe_export_folder filesep 'events.mat']);
    oe_events = struct2table(oe.data);
end

function plot_all_events(oe_events)
     scatter(oe_events.timestamp, double(oe_events.line) - double(oe_events.state)/5, '.')
end

function plot_xy(p)
    scatter(p(1),p(2))
end

function gaze_angle = calc_gaze_angle(track)
    ear_L = track{:,{'ear_L_x','ear_L_y'}};
    ear_R = track{:,{'ear_R_x','ear_R_y'}};
    v = ear_L-ear_R;
    gaze_angle = atan2d(v(:,2), v(:,1)) + 90;
    gaze_angle = mod(gaze_angle, 360);
end
function midpoint = calc_head_midpoint(track)
    ear_L = track{:,{'ear_L_x','ear_L_y'}};
    ear_R = track{:,{'ear_R_x','ear_R_y'}};
    midpoint = (ear_L+ear_R) / 2;
end

function theta = calc_angle_to_light(track, light)
    midpoint = calc_head_midpoint(track);
    v = light - midpoint;
    theta = atan2d(v(:,2), v(:,1));
    theta = mod(theta, 360);
end