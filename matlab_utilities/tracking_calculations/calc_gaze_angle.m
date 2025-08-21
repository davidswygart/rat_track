function gaze_angle = calc_gaze_angle(track)
    ear_L = track{:,{'ear_L_x','ear_L_y'}};
    ear_R = track{:,{'ear_R_x','ear_R_y'}};
    v = ear_L-ear_R;
    gaze_angle = atan2d(v(:,2), v(:,1)) + 90;
    gaze_angle = mod(gaze_angle, 360);
end