function keypress = play_video(video, start, stop, speedup) 
    % video should be a VideoReader object or a path to a video
    if nargin<4
        speedup=1;
    end

    if isa(video, 'VideoReader')
        vidObj = video;
    else
        vidObj = VideoReader(video);
    end
    frame_dur = 1 / vidObj.FrameRate / speedup;

    %% set callback function on keypress
    keypress = '';
    function keyPressCallback(~, event)
        keypress =  event.Key;
    end
    set(gcf, 'WindowKeyPressFcn', @keyPressCallback);
    %%
    hImg = imshow(zeros(vidObj.Height, vidObj.Width, 3), 'Parent', axes);
    vidObj.CurrentTime = start; 
    while hasFrame(vidObj) && vidObj.CurrentTime < stop
        frame = readFrame(vidObj);
        set(hImg, 'CData', frame);
        drawnow;
        pause(frame_dur);

        if ~isempty(keypress)
            return
        end
    end
end