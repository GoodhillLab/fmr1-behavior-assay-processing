# UniversalVideoReader

MATLAB is problematic when dealing with video files in a Linux environment.
For example, MATLAB in Linux requires additional codecs (often provided by GStreamer) to read in h264 encoded videos, however, GStreamer might not be pre-installed in some computing clusters.

This package provides a universal video reader for MATLAB in any OS.
It calls FFmpeg thus support any format that it supports. It uses dynamic caching to load videos in chunks.
If `numCachedFrames` was set to be 5000, it will call FFmpeg to decompress the input video every 5000 frames to an uncompressed AVI format.
This format is supported by MATLAB in every OS.
Due to the implement of caching, this reader is likely to be faster than MATLAB's built-in `VideoReader` class.


## Must read

### Framerate
For fast seeking, this reader enforces the framerate of the input file to be 25.
If you encounter the following error `assert(obj.FrameRate == 25, "Average framerate of the file has to be 25!");` upon creating the reader object, use the code below to fix/rewrite the framerate in your input file.

```Bash
ffmpeg -i <input> -hide_banner -loglevel error -f avi -r 25 -c:v copy <output>
```
`<input>` should be some H264 encoded file (e.g. mp4) and `<output>` should be ended with extension .avi

### Timestamps
If you can create the reader object, but gets error upon using `readFrame`, it's likely that the timestamps in the input mp4 file is a bit messed up.
The code below drops the previous timestamps and write in new, consistent timestamps with 25 FPS.

```Bash
INPUT=20211112-f21_10-09-50.000
FPS=25

ffmpeg -i $INPUT.mp4 -map 0:v -vcodec copy -bsf:v h264_mp4toannexb -loglevel panic $INPUT.h264 -y
ffmpeg -fflags +genpts -r $FPS -i $INPUT.h264 -vcodec copy tmp.mp4 -y
ffmpeg -i tmp.mp4 -hide_banner -loglevel error -f avi -r $FPS -c:v copy $INPUT.avi -y
```

After this is done, you can delete all the \*.mp4 and \*.h264 files, and use the .avi file as the input file to MATLAB.

## Usage

**This reader requires FFmpeg, download it and add it to your system's path.**

This reader has the same naming convention (for both function and variable names) as MATLAB's `VideoReader` class.
Functions like `read` and  `readFrame` are implemented.
`read` reads one specific frame and `readFrame` reads the next frame (much faster when you set a sensible `numCachedFrames`).
Below are the public variables which can be accessed with `.` (e.g. `v.NumFrames` where `v` is the reader object).
- NumFrames
- FrameRate
- Width
- Height


Below shows a basic example of creating the VideoReader object, using `read` and `readFrame`, note that numCachedFrames is only set to 500 for demonstration purpose, you may want to use something like 2000.

```MATLAB
v = UniversalVideoReader(fname_mp4, 'output.avi', 500);
frame_num = 1000;
frame1 = v.read(frame_num);
frame2 = v.readFrame();
```
