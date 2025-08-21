sip_lines = [4,3]; % OE event lines corresponding to L and R sippers

%% set time of interest
pre_time = 5; %time before sipper (light should start 5s prior)
post_time = 5; %time after sipper (sipper stays out for 8s)

%% set colors
c_light = [252,186,3]/255; % orange
c_wait = ones(1,3) * 1; % white
c_sip = [130,255,100]/255; % light green

c_gaze = [127,0,255]/255;% purple
c_dist = [0,102,204]/255; % cyan

%%
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
        is_trial = tracking.time>t-pre_time & tracking.time<t+post_time;
        trial = tracking(is_trial,:);
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














