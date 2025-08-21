function theta = calc_angle_to_light(track, light)
    midpoint = calc_head_midpoint(track);
    v = light - midpoint;
    theta = atan2d(v(:,2), v(:,1));
    theta = mod(theta, 360);
end