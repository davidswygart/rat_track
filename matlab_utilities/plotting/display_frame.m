function display_frame(video_path, frame_number)
    vidObj = VideoReader(video_path);
    time_offset = vidObj.CurrentTime;

    vidObj.CurrentTime = (frame_number - 1)/vidObj.FrameRate + time_offset;
    frame_number = readFrame(vidObj);
    frame_number = rgb2gray(frame_number);
    imshow(frame_number);
end