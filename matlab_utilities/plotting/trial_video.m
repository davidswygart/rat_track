function trial_video(t,video_path)
    vidObj = VideoReader(video_path);
    time_offset = vidObj.CurrentTime;

    for i = 1:height(t)-1
        vidObj.CurrentTime = (t.frame(i) - 1)/vidObj.FrameRate + time_offset;
        imshow(readFrame(vidObj));
        hold on

        scatter(t.ear_L_x(i),t.ear_L_y(i), '.g')
        scatter(t.ear_R_x(i),t.ear_R_y(i), '.b')
        plot_gaze(t(i:i+1,:), 'red')
        title(sprintf("f: %d", i))
        pause(1/30);
    end
end
