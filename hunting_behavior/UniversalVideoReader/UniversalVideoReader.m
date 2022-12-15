classdef UniversalVideoReader < handle
    % Universal video reader for MATLAB in any OS. It calls FFmpeg thus supports any formats FFmpeg supports.
    % This program makes system calls to FFmpeg binary to decompress given video to uncompressed AVI format.
    % The amount of frames decompressed each time depending on numCachedFrames when creating the reader object.

    properties(Access='public')
        filename;
        tmpfile;
        NumFrames;
        FrameRate;
        Width;
        Height;
    end
    
    properties(Access='private')
        cache;
        tmptmptmp;
        seq_file;
        numCachedFrames;
        currentFrame;
        cacheStartFrame;
        cacheEndFrame;
    end
    
    methods(Access='public')

        % init function which construct the reader object. Due to the implementation of cache, it's highly recommended
        % to pass the handler to downstream functions instead of creating a new reader object.
        % Example: v = UniversalVideoReader(fname, 'output.avi', 500); then just pass the v variable around in your program.

        % filename: filename of the video to be read. The video can be in any format that's supported by FFmpeg.
        % tmpfile: location of the tmp file (the decompressed video)
        % numCachedFrames: number of frames to decompress

        % Note that this program assumes the FPS of the video is 25FPS, for the fast seeking in frames.
        function obj = UniversalVideoReader(filename, tmpfile, numCachedFrames)
            %UNIVERSALVIDEOREADER Construct an instance of this class

            obj.filename = filename;
            obj.seq_file = false;
            [~,~,ext] = fileparts(filename);
            if ext == ".seq"
                obj.seq_file = true; % turn on support for seq files
            end


            if obj.seq_file
                header_info = seq_header(filename);
                obj.NumFrames = header_info.numFrames;
                obj.Width = header_info.ImageWidth;
                obj.Height = header_info.ImageHeight;
                obj.FrameRate = header_info.FrameRate;
            else
                cmdString = sprintf('ffprobe -v error -select_streams v:0 -show_entries stream=nb_frames -of default=nokey=1:noprint_wrappers=1 %s', filename);
                [status,cmdout] = system(cmdString);
                assert(status == 0, cmdout);
                obj.NumFrames = str2num(cmdout);

                cmdString = sprintf('ffprobe -v error -select_streams v:0 -show_entries stream=avg_frame_rate -of default=nokey=1:noprint_wrappers=1 %s', filename);
                [status,cmdout] = system(cmdString);
                assert(status == 0, cmdout);
                obj.FrameRate = str2num(cmdout);

                assert(obj.FrameRate == 25, "Average framerate of the file has to be 25!");

                obj.tmpfile = tmpfile;
                [ParentFolderPath] = fileparts(tmpfile);
                obj.tmptmptmp = fullfile(ParentFolderPath, 'tmptmptmp.avi');
                obj.numCachedFrames = numCachedFrames;
                obj.cacheStartFrame = 0;
                obj.cacheEndFrame = 0;

                frame_tmp = obj.read(1);
                obj.Width = size(frame_tmp, 2);
                obj.Height = size(frame_tmp, 1);
            end
            obj.currentFrame = 0;
        end
        

        % Read one specific frame from a video file.
        function frame = read(obj, frameNum)
            if obj.seq_file
                frame = seq_read(obj.filename, frameNum);
            else
                cmdString = sprintf('ffmpeg -vsync 0 -ss %.2f -i %s -frames:v 1 -f avi -c:v rawvideo -pix_fmt bgr24 %s -y', ...
                    (frameNum-1)/25, obj.filename, obj.tmptmptmp);
                [status,cmdout] = system(cmdString);
                assert(status == 0, cmdout);
                v = VideoReader(obj.tmptmptmp);
                frame = read(v);
            end
            frame = im2gray(frame);
        end
        

        % Read the next available frame from a video file.
        function frame = readFrame(obj)
            nextFrameNum = obj.currentFrame + 1;
            if obj.seq_file
                frame = seq_read(obj.filename, nextFrameNum);
            else
                if (nextFrameNum < obj.cacheStartFrame) || (nextFrameNum > obj.cacheEndFrame)
                    % need to update cache
                    obj.updateCache(nextFrameNum);
                end
                frame = obj.cache(:,:,:, nextFrameNum - obj.cacheStartFrame + 1);
            end
            frame = im2gray(frame);
            obj.currentFrame = nextFrameNum;
        end
    end
    

    % private function which updates the cache
    methods(Access='private')
        function obj = updateCache(obj, nextFrameNum)
            cmdString = sprintf('ffmpeg -vsync 0 -ss %.2f -i %s -frames:v %d -f avi -c:v rawvideo -pix_fmt bgr24 %s -y', ...
                (nextFrameNum-1)/25, obj.filename, obj.numCachedFrames, obj.tmpfile);
            [status,cmdout] = system(cmdString);
            assert(status == 0, cmdout);
            v = VideoReader(obj.tmpfile);
            obj.cache = read(v);
            obj.cacheStartFrame = nextFrameNum;
            obj.cacheEndFrame = nextFrameNum + size(obj.cache, 4) - 1;
        end
    end
end
