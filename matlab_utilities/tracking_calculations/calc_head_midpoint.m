function midpoint = calc_head_midpoint(track)
    ear_L = track{:,{'ear_L_x','ear_L_y'}};
    ear_R = track{:,{'ear_R_x','ear_R_y'}};
    midpoint = (ear_L+ear_R) / 2;
end