function gravel_preprocessing(data_path)
%GRAVEL_PREPROCESSING User input for gravel preference data tracking

%% Get min pixel threshold
% Fish is always bright so we can remove som extra noise with a minimum
% threshold. The aim here is to mask out the very dark parts of the image.
% The fish must be above the threshold
px_thr = input_pixel_threshold(data_path);

%% Annotate the initial positions of each fish
init_pos = initialise_tracks(data_path);

outfile = fullfile(data_path,'preprocess_out.mat');
save(outfile,'px_thr','init_pos')
end

