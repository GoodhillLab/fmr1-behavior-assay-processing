%%% Tracking of social behavior experiment
% Reads the tiff file of a social behavior experiment and track the
% position of the fish; calculate social preference index and distance
% travelled
% Code by Iris Zhu (2019)
%% set path and fish to track
path2Data = pwd;
fishName = 'fp1';
cond = 'CS';
fileName = strcat(fishName,'_',cond);
addpath('code');
%% select ROI of fish
fishTracking = generateROI(fileName,path2Data);
outfile = fullfile(path2Data,[fishName,'.mat']);
save(outfile,'fishTracking')
%% setting parameters;
setParams2(fishName,cond);
%% start tracking;
tracking3(fishName,cond);
%% calculate SPI and distance travelled
get_socialMeasures(path2Data,fishName);