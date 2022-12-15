function fish_coords = smooth_fish_coords(tracker_out,params)
%POST_PROCESSING Smooth fish trajectory and extract tail from skeleton
%   Post processing on the tracked fish coordinates and skeleton.

fish_coords = struct([]);

for m=1:size(tracker_out,2)
    tracker_out(m).w = 1024;
    tracker_out(m).h = 1024;
    K = tracker_out(m).K;
    % Note that the Kalman smoothing parameters are very mild. Tracking is
    % already quite good and the Kalman smoother struggles to resolve the
    % difference between random jitter and fast escape maneuvers.
    % Kalman smoothing for swim bladder
    fish_coords(m).swim_bladder = kalman_smoother_2d(tracker_out(m).swim_bladder(1:K,:)',tracker_out(m).t(1:K) ...
        ,params.kalman_r_process,params.kalman_r_measurement)';
    % Kalman smoothing for eye midpoint
    fish_coords(m).eye_midpoint = kalman_smoother_2d(tracker_out(m).eye_midpoint(1:K,:)',tracker_out(m).t(1:K) ...
        ,params.kalman_r_process,params.kalman_r_measurement)';
    fish_coords(m).t = tracker_out(m).t(1:K,:);
end