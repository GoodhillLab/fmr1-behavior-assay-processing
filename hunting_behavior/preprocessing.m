function preprocessing(data_path)
%PREPROCESSING Run pre-processing on fish in data_path

% Add code path
addpath('code', 'UniversalVideoReader');
%Create Video Objects
v = createVideoObjects(data_path);
% Get fish ID
fishID = data_path(end-11:end-1);
% Set tracking parameters
params.N_bg = 1000;
params.N_train = 10;
params.sz = 255;
params.scale_coef = linspace(0.64,1.00,10);
params.rot_angle = linspace(0,355,72);
params.sigma = 2;
params.eps = 1e-6;
params.aff_angles = [-6 -4 -2 2 4 6];
params.bin_size = 4;
params.n_orients = 9;
% Input arena mask
mask = input_arena_mask(data_path,v(1));
% Input image scale
params.image_scale = input_image_scale(data_path,v(1));
% Input pixel threshold
params.thr = input_pixel_threshold(data_path,v);
% Input annotations
ann = input_annotations(data_path,params.N_train,v);
% Save pre-processing outputs
save([data_path, 'preprocess_out.mat'], ...
    'fishID', ...
    'params', ...
    'mask', ...
    'ann')
end

