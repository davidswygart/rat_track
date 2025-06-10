video_csv = "/home/lapishla/Desktop/pv_videos/Anymaze_of_interest.csv";
sync_all_from_csv(video_csv)


function sync_all_from_csv(csv_path)

video_table = readtable(csv_path);
% video_table = video_table(~video_table.skip, :);

OE_export = "/home/lapishla/Desktop/pv_videos/katieExport/export/";
video_events_parent = "/home/lapishla/Desktop/pv_videos/cropped_video/";
video_table.tracking = cell(height(video_table),1);
for ind = 1:height(video_table)
    disp(ind)
    if video_table.skip(ind)
        disp("skipping because the CSV told me to")
        video_table.tracking{ind} = "skipping because the CSV told me to";
        continue
    end

    oe_events_path = OE_export + "/" + video_table.oe_export_folder(ind) + "/events.mat";
    if ~isfile(oe_events_path)
        warning("no OE event export found")
        video_table.tracking{ind} = "skipping: no OE event export found";
        continue
    end

    id = video_table.ID(ind);
    video_events_path = video_events_parent + "/" + num2str(id) + "_events.csv";
    if ~isfile(video_events_path)
        warning("no video event csv found")
        video_table.tracking{ind} = "skipping: no video event csv found";
        continue
    end

    tracking_parent = "/home/lapishla/Desktop/pv2cap-2-2025-05-28/videos/";
    model_post_string = "DLC_Resnet50_pv2capMay28shuffle1_snapshot_160.csv";
    tracking_csv = tracking_parent + num2str(id) + model_post_string;
    if ~isfile(tracking_csv)
        warning("no DLC tracking csv found")
        video_table.tracking{ind} = "skipping: no DLC tracking csv found";
        continue
    end

    if strcmp(video_table.Rig{ind}, 'A')
        left_right_oe_lines = [2, 1];
        disp("Rig A");
    elseif strcmp(video_table.Rig{ind}, 'B')
        left_right_oe_lines = [1, 2];
        disp("Rig B");
    end


    t = sync_single_experiment(oe_events_path, video_events_path, tracking_csv, left_right_oe_lines);

        % warning("Syncing to OE events failed")
        % continue

    video_table.tracking{ind} = t;

    %Temporary: For convenience add the corresponding oe export files.
    %Don't do this long term because file size will be huge.
    export_dir = OE_export + "/" + video_table.oe_export_folder(ind) ;
    video_table.oe_events{ind} = load(export_dir + "/events.mat");
    % video_table.oe_streams{ind} = load(export_dir + "/stream.mat");
    video_table.oe_spikes{ind} = load(export_dir + "/spikes.mat");
end

save(csv_path+".mat", "video_table")

end


function v_tracking = sync_single_experiment(oe_events_path, video_events_path, tracking_csv, left_right_oe_lines)
e = load(oe_events_path);
e = struct2table(e.data);
v = readtable(video_events_path);
%%
e = sortrows(e,"timestamp","ascend");
v = sortrows(v,"frame","ascend");
%% Find matching OE events and insert their timestamp
v.oe_times(:) = nan;
% Left ON
v = add_oe_times(v, 1, 'L', e, 0, left_right_oe_lines(1)); 
% Left OFF
v = add_oe_times(v, 0, 'L', e, 1, left_right_oe_lines(1));
% Right ON
v = add_oe_times(v, 1, 'R', e, 0, left_right_oe_lines(2));
% Right OFF
v = add_oe_times(v, 0, 'R', e, 1, left_right_oe_lines(2));
 
if ~any(~isnan(v.oe_times)) % If all are nan return empty
    warning("No events could be synced")
    v_tracking = "skipping: No events could be synced";
    return
else
    % Interpolate the tracking times based on the OE event times
    [v_tracking, model_name] = load_tracking_csv(tracking_csv);
    v_tracking = interp_oe_times(v, v_tracking);
    return
end
end

%% functions
function tracking = interp_oe_times(events, tracking)
not_nan = ~isnan(events.oe_times);
x = events.frame(not_nan);
v = events.oe_times(not_nan);
xq = tracking.frame;

[x,~,idx] = unique(x,'stable'); % check for duplicate values of x
v = accumarray(idx,v,[],@mean); % use mean v for duplicate x values

tracking.oe_times = interp1(x,v,xq, 'linear','extrap');
end

function [v_tracking, model_name] = load_tracking_csv(filename)
string_array = readcell(filename);

model_name = string_array(1,2);

bodypart = string(string_array(2, :));
coords = string(string_array(3, :));
headers = bodypart + "_" + coords;
headers(1,1) = "frame";

data = cell2mat(string_array(4:end,:));

v_tracking = array2table(data, 'VariableNames', headers);
end

function v = add_oe_times(v, state_v, side_v, e, state_e, line_e)
bool_v = v.state==state_v  &  strcmp(v.side, side_v);
bool_e = e.state==state_e  &  e.line==line_e;

v_frames = v.frame(bool_v);
e_times = e.timestamp(bool_e);

pattern_diff = plot_diff_patterns(v_frames, e_times);

len_v = length(v_frames);
len_e = length(e_times);
if len_v ~= len_e
    warning('video has %d events, but ephys has %d events', len_v, len_e)
    return
end

max_pattern_error = max(abs(pattern_diff));
if max_pattern_error > 0.1
    warning('max pattern difference of %f', max_pattern_error)
    return
end

v.oe_times(bool_v) = e_times;

figure(2); clf
scatter(v_frames, e_times)
xlabel('video frame')
ylabel('ephys time (s)')
end


function pattern_diff = plot_diff_patterns(v_frames, e_times)
    figure(1); clf; hold on;
    fps = 15;
    v_times = v_frames / fps;
    v_diff = diff(v_times);
    e_diff = diff(e_times);
    
    plot(v_diff)
    plot(e_diff)

    ylabel('time since last event (s)')
    xlabel('event number')
    legend('video', 'ephys')

    min_length = min([length(v_diff), length(e_diff)]);
    pattern_diff = v_diff(1:min_length) - e_diff(1:min_length);
end