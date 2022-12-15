function measure_fish(data_path)
%MEASURE_FISH Loads data and GUI for fish measurement

% Add code path
addpath('code')

% Load pre-processing
load([data_path, 'postprocess_out.mat'],'tail_coords','params')

fish_length = measure_fish_length(data_path,tail_coords,params);
save([data_path,'fish_length.mat'],'fish_length')

end
