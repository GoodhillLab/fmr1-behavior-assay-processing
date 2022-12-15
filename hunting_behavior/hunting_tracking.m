%%% Tracking and processing of hunting behavior assay
% Reads the mp4 file of a hunting behavior assay and tracks the
% tail, eye midpoint, swim bladder of the fish; Also tracks the location of
% paramecia.
% Code by Michael McCullough (2019)
%% set up the path to a hunting assay
data_path = pwd;
addpath('code', 'UniversalVideoReader');
%% preprocessing
preprocessing(data_path);
%% tracking
tracking(data_path);
%% postprocessing
postprocessing(data_path);
%% measure fish length
measure_fish(data_path);
