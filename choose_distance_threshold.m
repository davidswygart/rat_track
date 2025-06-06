mat_path = "/home/lapishla/Desktop/pv_videos/analyzed_trials.mat";
load(mat_path)

figure(1); clf; hold on;
plot_all_sessions(video_table, "nose")
figure(2); clf; hold on;
plot_all_sessions(video_table, "probe")
figure(3); clf; hold on;
plot_all_sessions(video_table, "mid_back")

function plot_all_sessions(video_table, part)
all_count = [];
for s = 1:height(video_table)
    sipper = video_table.sipper_points{s};
    track = video_table.tracking{s};
    
    dist = calc_session_distance(sipper, track, part);
    edges = 0:500;
    n = histcounts(dist,edges);
    plot(n)

    all_count = [all_count; n];
end
title(part)
xlabel('distance from sipper (pixels)')
ylabel('counts')

plot(mean(all_count), 'k', 'LineWidth',3)
end

function dist = calc_session_distance(sipper, track, part)
x = track(:,part+"_x");
y = track(:,part+"_y");
d_L = calc_distance(x,y,sipper(1,:));
d_R = calc_distance(x,y,sipper(2,:));

dist = [d_L;d_R];
end

function distance = calc_distance(tx,ty, sipper)
sx = sipper(1);
sy = sipper(2);

tx = table2array(tx);
ty = table2array(ty);

distance = sqrt( (tx-sx).^2 + (ty-sy).^2 );
end