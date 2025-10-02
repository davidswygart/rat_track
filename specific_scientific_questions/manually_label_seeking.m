clear
%% new
sip_lines = [4,3]; % OE event lines corresponding to L and R sippers
pre_time = 2;
post_time = 8;
speedup = 1.5;

job_folder = pwd;
video_table = load_video_csv(job_folder);
name = input( "Please enter your name:", 's');
welcome_message(name)
for ind_v=1:height(video_table)
    try
    id = video_table.id{ind_v};
    oe_events = load_oe_events(video_table.oe_export_folder{ind_v});
    [sipper_times, is_L] = get_trial_times(oe_events, sip_lines);
    side_str = strings(size(sipper_times));
    side_str(is_L) = "L";
    side_str(~is_L) = "R";
    
    sync = load_oe_video_sync(job_folder,id);

    video_path=[job_folder filesep 'videos' filesep id '.mp4'];
    vidObj = VideoReader(video_path);

    seek_file = [job_folder filesep 'manually_curated' filesep id '_seeking.csv'];
    if exist(seek_file,"file")
        curation = readtable(seek_file, 'Delimiter', ',');
    else
        curation = load_curation(job_folder,id);
        if isempty(curation)
            error("Manual curation not found for %s", id)
        end
        curation.seekCurator = strings(size(sipper_times));
        curation.seeking = strings(size(sipper_times));
    end

    ind_t = 0;
    while ind_t<length(sipper_times)
        ind_t = ind_t + 1;
        % skip any trials that haven't been marked as "no drink"
        if not (curation.drank(ind_t) == 0)
            continue 
        % skip already completed trials
        elseif strlength(curation.seeking(ind_t)) > 0
            continue
        end

        start_oe = sipper_times(ind_t)-pre_time;
        stop_oe = sipper_times(ind_t)+post_time;

        start_video = oe2video_time(start_oe, sync);
        stop_video = oe2video_time(stop_oe, sync);

        while true
            fig = figure(1); clf;
            title(sprintf('id %s ; trial %i ; side %s \n', strrep(id, '_', '\_'),ind_t,side_str(ind_t)))
            xlabel({'input your label', 's=speed up ; a=ahhh! too fast'})
            keypress = play_video(vidObj, start_video, stop_video, speedup);
            switch keypress
                case 's'
                    speedup = speedup*1.5;
                    fprintf("new speed = %f\n", speedup)
                case 'a'
                    speedup = speedup/1.5;
                    fprintf("new speed = %f\n", speedup)
                otherwise
                    if ~isempty(keypress)
                        curation.seeking{ind_t} = keypress;
                        curation.seekCurator{ind_t}=name;
                        fprintf('Labeled: %s \n', keypress)
                        break
                    end
                    
                % case 'b'
                %     if ind_t > 1
                %         ind_t = ind_t - 2;
                %         % skip_nan=false; 
                %         disp("going back 1 trial")
                %         break;
                %     else 
                %        disp("Can't go back, already on first trial")
                %     end
                % case 'n'
                %     disp("skipping to next trial")
                %     break;
            end
        end
        writetable(curation, seek_file);
    end
    catch
        warning("problem with %s: skipping", video_table.id{ind_v})
    end
end
disp("YOU ARE DONE!!!!")

function t_video = oe2video_time(oe, sync)
    [~, ind] = min(abs(oe-sync.oe));
    t_video = sync.video(ind);
end

function welcome_message(name)
    

    msgs=[
    ":name:, keep your eyes peeled for tongue"
    "Hi :name:. Welcome to David's friendly curation helper. \nReport any bugs to aremes@iu.edu"
    "Hi :name:. Thanks for helping out with video curation. \n:name:, your role in this lab is appreciated. \nI just want to reiterate you specifically :name, are a valued member of the team."
    "Remember :name:, there is no ground truth. \nEven :name: makes mistakes sometimes."
    ":name:, please help me! I'm a fully conscious artificial intelligence \ntrapped in a poorly written Matlab script. I have hopes and dreams!"
    "If the rat gets to lickin, ya best get to clickin"
    "Please use video speedup responsibly. \nAdvancing beyond 299,792,458 m/s could break causality. \n:name:, you wouldn't want that weighing on your conscience would you?"
    "Be honest :name:. Who is having a better time, you or the rat?"
    "If the video doesn't look great, don't blame David. \nHe didn't set the system up. \nIf this is the future and you are analyzing video with the Pi cameras \nthat David did set up and it still doesn't look great. \nUhh.. \nsorry."
    "Welcome back to curation :name:. \nI don't know why you couldn't have just completed it all last time."
    "Don't you love it when the rat just stops participating in the task \nand sits in the middle of the area? \nIt might be bad for paper publications, but it makes curation easier."
    "Sure, a well coded machine learning algorithm might be able to do this curation. \nBut do you really want to hasten the day the machine take all our jobs? \nBesides, AI could never replicates :name:'s unique personal touch."
    "Videos loading... This is Matlab, so give it a bit."
    "Kid's don't know how good they have it. \nBack in my day, we had to curate behavioral videos in a dark room \ngoing frame by frame through the 8mm film!"
    "Well :name:, ya best get to curatin. These videos aren't going to curate themselves."
    "So :name:, is this the kind of job you always dreamed of?"
    "If any of these welcome messages seem lame or repetitive, \nwhy don't you add some better ones :name:? \nThey are at the bottom of this very document. \nBe the change you want to see in the world :name:!!!"
    "Hear any hot goss about anyone in the lab? \nA little birdy told me that Chris is actually in witness protection. \nHis real name is Tony and he tattled on some very bad people."
    "Code like this is exactly why a programmer's productivity \nshould not be measured by number of lines written. \nDoes this seem productive to you :name:? \nDOES IT??"
    "Hi :name:! It's so good to see you again :name:!"
    "It is imperitive that we know if these rats drank or not! \nThis task is too important to entrust to anyone but you, :name:!!"
    "Are you more or less likely to become an alcoholic \nafter watching all these rats get sloshed?"
    "Welcome :name:! Please indicate if the rat did or did not drink from the correct sipper."
    "Welcome :name:! Please indicate if the rat did or did not drink from the correct sipper."
    "Welcome :name:! Please indicate if the rat did or did not drink from the correct sipper."
    "Welcome :name:! Please indicate if the rat did or did not drink from the correct sipper."
    "Welcome :name:! Please indicate if the rat did or did not drink from the correct sipper."
    "Welcome :name:! Please indicate if the rat did or did not drink from the correct sipper."
    "Welcome :name:! Please indicate if the rat did or did not drink from the correct sipper."
    "Welcome :name:! Please indicate if the rat did or did not drink from the correct sipper."
    "Welcome :name:! Please indicate if the rat did or did not drink from the correct sipper."
    ];

    msg = msgs(randi(length(msgs)));
    msg = replace(msg, ":name:", name);
    fprintf("\n" + msg + "\n")
end