function [v] = createVideoObjects(data_path)
%Find the video files in the directory. Prioritize running mp4.
%The 
    %Find video files
    files = dir(data_path);
    files = files(~ismember({files.name},{'.','..'}));
    types = ["mp4","seq"];
    files = files(contains({files.name},types(1)));
    if isempty(files)
        files = files(contains({files.name},types(2)));
    end
    %Create video objects
    cache_size=2000;
    for j = 1:length(files)
        file_name = fullfile(files(j).folder, files(j).name);
        v(j) = UniversalVideoReader(file_name, fullfile(data_path, 'output.avi'), cache_size);
    end

end
