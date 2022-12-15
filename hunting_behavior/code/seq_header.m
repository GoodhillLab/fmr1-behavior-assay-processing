function header_info = seq_header(file_name)
% Open NORPIX seq file and return the headers including time stamps
%
% ARGUMENTS:
%    INPUTS:
%    fileName: String name/path of image
%    OUTPUTS:
%    headerInfo: Structure containing Norpix version, header size (bytes),
%            description, image width, image height, image bit depth, image
%            bit depth (real), image size (bytes), image format, number of
%            allocated frames, origin, true image size, and frame rate.
%            (The user is referred to the manual for discussions of these
%            values.) Also returns the timestamp of each frame, in
%            Coordinated Universal Time (UTC).
%
% This code is heavily adpated and modified from the original version
% titled Norpix2MATLAB which was written 04/08/08 by Brett Shoelson, PhD
% (brett.shoelson@mathworks.com)
%
% LAST UPDATED 01/03/2019
%
% NOT FOR DISTRIBUTION OUTSIDE OF THE LAB


%% Open file for reading at the beginning
fid = fopen(file_name,'r','b');

% Both sequences are 640x480, 5 images each.
% The 12 bit sequence is little endian, aligned on 16 bit.
% The header of the sequence is 1024 bytes long.
% After that you have the first image that has
%
% 640 x 480 = 307200 bytes for the 8 bit sequence:
% or
% 640 x 480 x 2 = 614400 bytes for the 12 bit sequence:
%
% After each image there are timestampBytes bytes that contain timestamp information.
%
% This image size, together with the timestampBytes bytes for the timestamp,
% are then aligned on 512 bytes.
%
% So the beginning of the second image will be at
% 1024 + (307200 + timestampBytes + 506) for the 8 bit
% or
% 1024 + (614400 + timestampBytes + 506) for the 12 bit


%% HEADER INFORMATION
% A sequence file is made of a header section located in the first 1024
% bytes. The header contains information pertaining to the whole sequence:
% image size and format, frame rate, number of images etc.
% OBF = {Offset (bytes), Bytes, Format}

% Use the Little Endian machine format ordering for reading bytes
endianType = 'ieee-le';

% Read header

OFB = {28,1,'long'};
fseek(fid,OFB{1}, 'bof');
header_info.Version = fread(fid, OFB{2}, OFB{3}, endianType);
% headerInfo.Version

%
OFB = {32,4/4,'long'};
fseek(fid,OFB{1}, 'bof');
header_info.HeaderSize = fread(fid,OFB{2},OFB{3}, endianType);
if  header_info.Version >=5
    %fprintf('Version 5+ detected, overriding reported header size')
    header_info.HeaderSize = 8192;
end
% headerInfo.HeaderSize

%
OFB = {592,1,'long'};
fseek(fid,OFB{1}, 'bof');
DescriptionFormat = fread(fid,OFB{2},OFB{3}, endianType)';
OFB = {36,512,'ushort'};
fseek(fid,OFB{1}, 'bof');
header_info.Description = fread(fid,OFB{2},OFB{3}, endianType)';
if DescriptionFormat == 0 %#ok Unicode
    header_info.Description = native2unicode(header_info.Description);
elseif DescriptionFormat == 1 %#ok ASCII
    header_info.Description = char(header_info.Description);
end
% headerInfo.Description

%
OFB = {548,24,'uint32'};
fseek(fid,OFB{1}, 'bof');
tmp = fread(fid,OFB{2},OFB{3}, 0, endianType);
header_info.ImageWidth = tmp(1);
header_info.ImageHeight = tmp(2);
header_info.ImageBitDepth = tmp(3);
header_info.ImageBitDepthReal = tmp(4);
header_info.ImageSizeBytes = tmp(5);
vals = [0,100,101,200:100:600,610,620,700,800,900];
fmts = {'Unknown','Monochrome','Raw Bayer','BGR','Planar','RGB',...
    'BGRx', 'YUV422', 'YUV422_20', 'YUV422_PPACKED', 'UVY422', 'UVY411', 'UVY444'};
header_info.ImageFormat = fmts{vals == tmp(6)};
%

% AllocatedFrames IS NOT EQUAL to the the true number of frames. Use
% numFrames instead (computed below).
% OFB = {572,1,'ushort'};
% fseek(fid,OFB{1}, 'bof');
% headerInfo.AllocatedFrames = fread(fid,OFB{2},OFB{3}, endianType);
% % headerInfo.AllocatedFrames

%
OFB = {576,1,'ushort'};
fseek(fid,OFB{1}, 'bof');
header_info.Origin = fread(fid,OFB{2},OFB{3}, endianType);
% headerInfo.Origin

%
OFB = {580,1,'ulong'};
fseek(fid,OFB{1}, 'bof');
header_info.TrueImageSize = fread(fid,OFB{2},OFB{3}, endianType);
% headerInfo.TrueImageSize

%
OFB = {584,1,'double'};
fseek(fid,OFB{1}, 'bof');
header_info.FrameRate = fread(fid,OFB{2},OFB{3}, endianType);
% headerInfo.FrameRate

%% Get actual number of frames (because headerInfo.Allocated frames is not equal to the number of frames)
directoryInfo = dir(file_name);
fileSize = directoryInfo.bytes;
header_info.numFrames = (fileSize-8192)/header_info.TrueImageSize;

%% Close the seq file
fclose(fid);

end

