function plot_corners(poi)
    xy = poi{{'corner_LL', 'corner_LR', 'corner_UR', 'corner_UL','corner_LL'},:};
    plot(xy(:,1), xy(:,2), '--k')
end