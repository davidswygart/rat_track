function play_video(path, start, stop)
    vidObj = VideoReader(path);
    frame_dur = 1 / vidObj.FrameRate;

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