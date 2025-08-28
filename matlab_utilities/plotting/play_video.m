function play_video(video, start, stop, speedup) 
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

    hAxes = axes;
    hImg = imshow(zeros(vidObj.Height, vidObj.Width, 3), 'Parent', hAxes);
    vidObj.CurrentTime = start; 
    while hasFrame(vidObj) && vidObj.CurrentTime < stop
        frame = readFrame(vidObj);
        set(hImg, 'CData', frame);
        drawnow;
        pause(frame_dur);
    end
end