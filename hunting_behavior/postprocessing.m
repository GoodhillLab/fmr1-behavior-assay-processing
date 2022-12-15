function postprocessing(data_path)
%POST_PROCESSING Transforms tracking output into usable time series data
%   Takes tracking_output as input, and outputs smoothed trajectories for
%   the fish coordinates, tail coordinates, tail curvature model, detected
%   bouts and assigns prey detections to tracks.

% Add code path
addpath('code')

% Load pre-processing
load([data_path, 'preprocess_out.mat'],'fishID','params','mask')

% Load tracker_out
load([data_path, 'tracker_out.mat'],'tracker_out')

% Set post_processing parameters
params.kalman_r_process = 1; % very mild smoothing because zebrafish swim dynamics are highly discontinuous (ideally would like to smooth more to reduce detection jitter but some high speed bouts have jerk that is comparable to the noise and would get incorrectly smoothed)
params.kalman_r_measurement = 4; % ditto above
params.n_tail_points = 101;
params.bout_thresh = 1; % by inspection
params.min_bout_time = 15; % by inspection from the PSD (15 is approx 2/3 period of the average tail beat oscillation)
params.bout_max_freq = 25; % by inspection from the PSD from a 9dpf fish (the peak of the PSD was at ~28Hz and dropped to noise level by ~45Hz)

% Smooth fish coordinates
fish_coords = smooth_fish_coords(tracker_out,params);

% Smooth tail coordinates
tail_coords = smooth_tail(tracker_out,fish_coords,params);

% Compute tail curvature model
tail_curve = compute_tail_curvature(fish_coords,tail_coords);

% Detect bouts
bouts = detect_bouts(fish_coords,tail_curve,params);

% Assign prey tracks
prey_coords = assign_prey_tracks(tracker_out,mask);

% Copy bad frame flag
for m=1:size(tracker_out,2)
    bad_frame{m} = tracker_out(m).bad_frame;
end

% Save output
save([data_path, 'postprocess_out.mat'], ...
    'fishID', ...
    'params', ...
    'fish_coords', ...
    'tail_coords', ...
    'tail_curve', ...
    'bouts', ...
    'prey_coords', ...
    'mask', ...
    'bad_frame', ...
    '-v7.3')
end

