function f = scale_factor(poi)
    known_sipper_dist_mm = 420;
    v = poi{'sipper_left',:} - poi{'sipper_right',:};
    dist_pixels = sqrt(sum(v.^2, 2));
    f = known_sipper_dist_mm / dist_pixels;
end