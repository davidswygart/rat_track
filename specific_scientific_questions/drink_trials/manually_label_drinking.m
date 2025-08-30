clear
%% new
sip_lines = [4,3]; % OE event lines corresponding to L and R sippers
pre_time = 2;
post_time = 8;
speedup = 1.5;

job_folder = pwd;
video_table = load_video_csv(job_folder);
name = input( "Please enter your name:", 's');
for ind_v=1:height(video_table)
    id = video_table.id{ind_v};
    oe_events = load_oe_events(video_table.oe_export_folder{ind_v});
    [sipper_times, is_L] = get_trial_times(oe_events, sip_lines);
    side_str = strings(size(sipper_times));
    side_str(is_L) = "L";
    side_str(~is_L) = "R";
    
    sync = load_oe_video_sync(job_folder,id);

    video_path=[job_folder filesep 'videos' filesep id '.mp4'];
    vidObj = VideoReader(video_path);

    [curation, curation_file] = load_curation(job_folder,id);
    if isempty(curation)
        curation = table(nan(size(sipper_times)), strings(size(sipper_times)), 'VariableNames', {'drank', 'curator'});
    end

    for ind_t = 1:length(sipper_times)
        if ~isnan(curation.drank(ind_t))
            fprintf("\n trial #%i already curated \n", ind_t)
            continue
        end
        start_oe = sipper_times(ind_t)-pre_time;
        stop_oe = sipper_times(ind_t)+post_time;

        start_video = oe2video_time(start_oe, sync);
        stop_video = oe2video_time(stop_oe, sync);

        while true
            fig = figure(1); clf;
            title(sprintf('id %s ; trial %i ; side %s \n', strrep(id, '_', '\_'),ind_t,side_str(ind_t)))
            xlabel({'d=drank ; f=failed to drink ', 's=speed up ; a=ahhh! too fast'})
            keypress = play_video(vidObj, start_video, stop_video, speedup);
            switch keypress
                case 'd'
                    curation.drank(ind_t) = 1;
                    curation.curator{ind_t}=name;
                    disp('labeled drink')
                    break;
                case 'f'
                    curation.drank(ind_t) = 0;
                    curation.curator{ind_t}=name;
                    disp('labeled No-drink')
                    break;
                case 's'
                    speedup = speedup*1.5;
                    fprintf("new speed = %f\n", speedup)
                case 'a'
                    speedup = speedup/1.5;
                    fprintf("new speed = %f\n", speedup)
            end
        end
        writetable(curation, curation_file);
    end
end
disp("YOU ARE DONE!!!!")

function t_video = oe2video_time(oe, sync)
    [~, ind] = min(abs(oe-sync.oe));
    t_video = sync.video(ind);
end

