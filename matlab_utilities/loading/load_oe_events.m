function oe_events = load_oe_events(oe_export_folder)
    fprintf("loading %s \n", oe_export_folder)
    oe = load([oe_export_folder filesep 'events.mat']);
    oe_events = struct2table(oe.data);
end