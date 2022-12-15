function boundary = get_boundary(data_path)
%INITIALISE_TRACKS Manually find fish in the first frame
files = dir(fullfile(data_path,'*.mp4'));
files = files(~ismember({files.name},{'output.mp4'}));


fpath = fullfile(data_path,files.name);
fprintf('Reading video details...')
v = VideoReader(fpath);

f = v.readFrame();
f = f(:,:,1);

fprintf([[], ...
'(1) Draw line from bottom to top along gravel boundary.\n',...
'Close the figure window when finished.\n'])
h = figure();
imshow(f);
poi = drawline();
pts = poi.Position;
uiwait;

pts = sortrows(pts,2); % fix in case line drawn in wrong direction
boundary = polyfit(pts(:,1),pts(:,2),1);
end

