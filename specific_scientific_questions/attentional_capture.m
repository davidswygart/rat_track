

%%
sip_lines = [4,3]; % OE event lines corresponding to L and R sippers
pre_time = 5; %time before sipper (light should start 5s prior)
post_time = 5; %time after sipper (sipper stays out for 8s)

job_folder = pwd;
csv_path = [job_folder filesep 'videos.csv'];
video_table = readtable(csv_path, 'Delimiter', ',');

for ind=1:1%height(video_table)
    id = video_table.id{ind};

    video_path=[job_folder filesep 'videos' filesep id '.mp4'];

    % load OE events
    oe_events = load_oe_events(video_table.oe_export_folder{ind});
    poi = load_poi(job_folder, id);

    % load tracking (also loads oe time sync)
    tracking = get_all_tracking(job_folder, id);
    [time, is_L] = get_trial_times(oe_events, sip_lines);

    for ind_t = 11:11%length(time)
        t=time(ind_t);
        trial = split_by_time(tracking, [t-pre_time,t+post_time]);
        t_time = trial.time - t;
        
        if is_L(ind_t)
            light = poi{{'light_left'},:};
            sipper = poi{{'sipper_left'}, :};
        else
            light = poi{{'light_right'},:};
            sipper = poi{{'sipper_right'}, :};
        end

        % figure(3); clf; hold on;
        % trial_video(trial,video_path)

        % light_start = [-5;-4;-3;-2];
        % light_stop = light_start+0.25;
        light_start = -5;
        light_stop = light_start+4;

        c_light = [252,186,3]/255; % orange
        c_wait = ones(1,3) * 1; % white
        c_sip = [130,255,100]/255; % light green

        c_gaze = [127,0,255]/255;% purple
        c_dist = [0,102,204]/255; % cyan


        figure(1); clf; hold on;
        % f= trial.frame(diff(t_time<-1)<0)+2; %last frame of CS+
        t_of_interest = -2.95;
        [~, interest_ind] = min(abs(t_time - t_of_interest));
        f= trial.frame(interest_ind); 
        display_frame(video_path, f)
        hold on;

        % scatter(light(:,1), light(:,2), 'filled','red')
        plot_corners(poi)
        text(light(:,1), light(:,2),'L',color="white",FontWeight='bold', HorizontalAlignment='center', VerticalAlignment='middle')
        text(sipper(:,1), sipper(:,2),'S',color="white",FontWeight='bold', HorizontalAlignment='center', VerticalAlignment='middle')
        % plot_gaze(pre_light, "magenta");
        % plot_gaze(mid_light, c_light);
        % plot_gaze(sip_wait, c_wait);
        % plot_gaze(sip_post, c_sip);
        color = repmat(c_wait, height(trial),1);
        for i=1:length(light_start)
            is_L = t_time>=light_start(i) & t_time<light_stop(i);
            color(is_L,:) = repmat(c_light, sum(is_L), 1);
        end
        
        is_S = t_time>=0 & t_time<8;
        color(is_S,:) = repmat(c_sip, sum(is_S), 1);
        plot_gaze(trial, color);
        xlim([1,640])
        ylim([1,480])
        daspect([1 1 1])
        %scale bar
        bar_length = 75;
        x=400;
        x = [x, x+bar_length/scale_factor(poi)];
        y=[375,375];
        plot(x,y, 'k', LineWidth=3)
        text(mean(x),y(1),'75 mm',FontWeight='bold',HorizontalAlignment='center',VerticalAlignment='bottom')
        % title(sprintf("Video: %d \nTrial: %d", ind, ind_t))
        axis off

        gaze_angle = calc_gaze_angle(trial);
        light_angle = calc_angle_to_light(trial, light);
        gaze_diff =  gaze_angle - light_angle;
        % gaze_diff =  gaze_angle - calc_angle_to_light(trial, sipper);

        gaze_diff = abs(mod(gaze_diff+180,360)-180);


        sip_dist_pix = calc_dist_to_sipper(trial, sipper);
        sip_dist_mm = sip_dist_pix*scale_factor(poi);

        figure(2); clf; hold on;
        % light rectangle and text
        for i=1:length(light_start)
            width = light_stop(i) - light_start(i);
            rectangle(Position=[light_start(i),0,width,180], FaceColor=c_light, EdgeColor=c_light)
            text(light_start(i)+width/2, 178, 'CS+', HorizontalAlignment='center', VerticalAlignment='top')
        end
         % wait rectangle
        rectangle(Position=[-1,0,1,180], FaceColor=c_wait, EdgeColor=c_wait)
        % sipper rectangle and text
        rectangle(Position=[0,0,8,180], FaceColor=c_sip, EdgeColor=c_sip)
        text(post_time/2 , 178, 'sipper', HorizontalAlignment='center', VerticalAlignment='top')
        % plot gaze_diff
        plot(t_time, gaze_diff, LineWidth=3, Color=c_gaze)
        ylabel("Gaze offset from CS+ (°)")
        ylim([0,180])
        % plot distance from sipper
        yyaxis right
        plot(t_time, sip_dist_mm, LineWidth=3, Color=c_dist)
        ylabel("Distance to sipper (mm)")
        ylim([0 420])
        xlim([-pre_time,post_time])
        xlabel("time before sipper (s)")
        ax = gca;
        ax.YAxis(1).Color = c_gaze;
        ax.YAxis(2).Color = c_dist;
        % title(sprintf("Video: %d \nTrial: %d", ind, ind_t))
        xline(t_time(interest_ind), '--')
        set(gca, 'Layer','top')
        pause(1);
    end
end
function plot_corners(poi)
    xy = poi{{'corner_LL', 'corner_LR', 'corner_UR', 'corner_UL','corner_LL'},:};
    plot(xy(:,1), xy(:,2), '--k')
end

function f = scale_factor(poi)
    known_sipper_dist_mm = 420;
    v = poi{'sipper_left',:} - poi{'sipper_right',:};
    dist_pixels = sqrt(sum(v.^2, 2));
    f = known_sipper_dist_mm / dist_pixels;
end
function sip_dist = calc_dist_to_sipper(trial, sipper)
    midpoint = calc_head_midpoint(trial);
    v = midpoint-sipper;
    sip_dist = sqrt(sum(v.^2, 2));
end

function track = split_by_time(track, tlim)
    is_trial = track.time>tlim(1) & track.time<tlim(2);
    track = track(is_trial,:);
end
function plot_gaze(track, color)
    gaze_angle = calc_gaze_angle(track);
    
    midpoint = calc_head_midpoint(track);

    scale = abs(mod(diff(gaze_angle)+180, 360)-180);
    scale = (scale+1) * 2;
    scale = [0;scale];% first scale is unknown without angle difference
    % scale = 30;
    dx = scale .* cosd(gaze_angle);
    dy = scale .* sind(gaze_angle);

    for i=1:length(gaze_angle)
        h=quiver(midpoint(i,1),midpoint(i,2),dx(i),dy(i),0);
        h.Color = color(i,:);
        h.LineWidth = 2;
    end

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
    frame = rgb2gray(frame);
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