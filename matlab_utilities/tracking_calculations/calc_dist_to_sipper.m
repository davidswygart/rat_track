
function sip_dist = calc_dist_to_sipper(trial, sipper)
    midpoint = calc_head_midpoint(trial);
    v = midpoint-sipper;
    sip_dist = sqrt(sum(v.^2, 2));
end
