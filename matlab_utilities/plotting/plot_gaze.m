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