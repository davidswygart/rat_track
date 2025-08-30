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

    set(gcf, 'WindowKeyPressFcn', @keyPressCallback);

    hAxes = axes;
    hImg = imshow(zeros(vidObj.Height, vidObj.Width, 3), 'Parent', hAxes);
    vidObj.CurrentTime = start; 
    while hasFrame(vidObj) && vidObj.CurrentTime < stop
        frame = readFrame(vidObj);
        set(hImg, 'CData', frame);
        drawnow;
        pause(frame_dur);

        k = get(gcf, 'UserData');
        if ~isempty(k)
            keypress = k;
            set(gcf, 'UserData', '')
            return
        end
    end
    keypress = '';
    cla('reset')
end

function keyPressCallback(src, event)
    set(src, 'UserData', event.Key)
end