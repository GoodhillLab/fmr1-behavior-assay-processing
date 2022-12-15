function init_tracks = initialise_tracks(data_path)
%INITIALISE_TRACKS Manually find fish in the first frame
files = dir(fullfile(data_path,'*.mp4'));
fpath = fullfile(data_path,files.name);
fprintf('Reading video details...')
v = VideoReader(fpath);

f = v.readFrame();
f = f(:,:,1);

fprintf([[], ...
'(1) Click to place a point on each fish.\n',...
'Close the figure window when finished.\n'])
h = figure();
imshow(f);
for i=1:4
    poi(i) = drawpoint();
    pts(i,:) = poi(i).Position;
end
uiwait;
init_tracks = pts;
end

