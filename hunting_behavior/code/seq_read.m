function [img_out, time_stamp] = seq_read(file_name,frame_number)
% Return a single frame from NORPIX seq file
%
% ARGUMENTS:
%    INPUTS:
%    fileName: String name/path of image
%    frameNumber: Index of the frame to return
%    OUTPUTS:
%    imgOut: the ImageHeight x ImageWidth frame
%    timeStamp: the time stamp of the frame
%
% This code is heavily adpated and modified from the original version
% titled Norpix2MATLAB which was written 04/08/08 by Brett Shoelson, PhD
% (brett.shoelson@mathworks.com)
%
% NOT FOR DISTRIBUTION OUTSIDE OF THE LAB

%% Open file for reading at the beginning
fid = fopen(file_name,'r','b');

%% HEADER INFORMATION
% A sequence file is made of a header section located in the first 1024
% bytes. The header contains information pertaining to the whole sequence:
% image size and format, frame rate, number of images etc.
% OBF = {Offset (bytes), Bytes, Format}

% Use the Little Endian machine format ordering for reading bytes
endianType = 'ieee-le';

OFB = {548,24,'uint32'};
fseek(fid,OFB{1}, 'bof');
tmp = fread(fid,OFB{2},OFB{3}, 0, endianType);
headerInfo.ImageWidth = tmp(1);
headerInfo.ImageHeight = tmp(2);
headerInfo.ImageBitDepthReal = tmp(4);

OFB = {580,1,'ulong'};
fseek(fid,OFB{1}, 'bof');
headerInfo.TrueImageSize = fread(fid,OFB{2},OFB{3}, endianType);

%% Reading images
% Following the header, each images is stored and aligned on a 8192 bytes
% boundary (when no metadata is included)
imageOffset = 8192;

switch headerInfo.ImageBitDepthReal
    case 8
        bitstr = 'uint8';
    case {10,12,14,16}
        bitstr = 'uint16';
end
if isempty(bitstr)
    error('Unsupported bit depth');
end

% Frame number to read;
nread = frame_number-1;

% Go to the start of the current frame about to be read in. The first frame starts
% after the header. Images are then sequential after the header. Reference for
% file read position is the "beginning of file".
fseek(fid, imageOffset + nread * headerInfo.TrueImageSize, 'bof');

% Read, interpret and convert the data dependent on its format
bitstr = '*uint8';
% For 8-bit frames, each pixel from each channel is 1 byte
numPixels = headerInfo.ImageWidth * headerInfo.ImageHeight;
% Read the current frame to a temporary column vector
%MONOcolVec =uint8.empty();
MONOcolVec = fread(fid, numPixels, bitstr, endianType);
MONOimg = reshape(MONOcolVec,headerInfo.ImageWidth,headerInfo.ImageHeight)';
img_out = MONOimg;

% Immediately after each frame is the 8 byte absolute timestamp at which the image
% was recorded.
% Read the next 32 bit (4 bytes) for the timestamp in seconds, formatted according
% to the C standard time_t data structure (32-bit)
timeSecsPOSIX = fread(fid, 1, 'int32', endianType);
% Read the next 4 bytes as two 16-bit numbers (2 bytes each) to get the
% millisecond and microsecond parts of the timestamp
subSeconds = fread(fid,2,'uint16', endianType);
% Convert the timestamp in seconds from POSIX time to typical datenum format
timeDateNum = timeSecsPOSIX/86400 + datenum(1970,1,1);
% Combine all numbers into a single timestamp
%subSeconds = round(subSeconds(1)+subSeconds(2)*1e-2);
time_stamp = [datestr(timeDateNum,'yyyy-mm-dd HH:MM:SS') '.' ...
    sprintf('%03d',subSeconds(1))];

%% Close the seq file
fclose(fid);
end

