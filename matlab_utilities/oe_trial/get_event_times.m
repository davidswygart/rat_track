function [on, dur] = get_event_times(oe_events, line)
    e = oe_events(oe_events.line==line, :);
    % assumes first event state is ON, and each ON is followed by OFF
    if length(unique(e.state)) > 2
        error('more than 2 OE event states')
    end
    if any(diff(e.state) == 0)
        error('unexpected repeated OE event state') 
    end

    on = e.timestamp(1:2:end);
    off = e.timestamp(2:2:end);
    if length(on) ~= length(off)
        error('unequal number of ON and OFF OE event')
    end
    
    dur = off-on;
end