%%% Tracking of gravel preference experiment
% Reads the mp4 file of a gravel preference experiment and track the
% position of the fish; Also calculates gravel preference index and
% distance travelled.
% Code by Michael McCullough (2020)
%% set path 
gravel_path = 'D:/gravel_preference/data/';
fish_name = 'f1';
data_path = fullfile(gravel_path,fish_name);
addpath('code');
%% preprocessing
gravel_preprocessing(data_path)
boundary = get_boundary(data_path);
outfile = fullfile(data_path,'gravel_boundary.mat');
save(outfile,'boundary')
%% tracking
detections = tracker(data_path,px_thr,false,false);
raw_tracks = assign_tracks(detections,init_pos);
tracks = link_tracks(raw_tracks,init_pos);
outfile = fullfile(data_path,'tracking_out.mat');
save(outfile,'tracks','raw_tracks','detections')
%% calculate gravel preference
[gravel_pref,distance] = get_gravelPreference(tracks,boundary);
outfile = fullfile(data_path,'gravel_preference_results.mat');
save(outfile,'gravel_pref','distance')
