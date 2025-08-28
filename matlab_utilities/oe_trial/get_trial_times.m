function [time, is_L] = get_trial_times(oe_events, sip_lines)
    sip_dur_threshold = 2; % non-trial sipper pulses for 0.5s, trial sipper pulses for 8s
    
    % get onset times for left and right sipper, filter by event duration
    [L_on, L_dur] = get_event_times(oe_events, sip_lines(1));
    L_on = L_on(L_dur>sip_dur_threshold);
    [R_on, R_dur] = get_event_times(oe_events, sip_lines(2));
    R_on = R_on(R_dur>sip_dur_threshold);

    % merge left and right trial times
    time = [L_on; R_on];
    is_L = zeros(size(time));
    is_L(1:length(L_on)) = 1;

    % sort by time
    [time, sort_ind] = sort(time);
    is_L = is_L(sort_ind);
    is_L = logical(is_L);
end