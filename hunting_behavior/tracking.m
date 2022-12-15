function tracking(data_path)
%TRACKING Run background model fit, filter training and tracking

% Add code path
addpath('code', 'UniversalVideoReader')
%Create Video Objects
v = createVideoObjects(data_path);
% Load pre-processing output
load([data_path, 'preprocess_out.mat'],'fishID','params','mask','ann')
% Background model fit
bg = fit_background_model(data_path,params.N_bg,mask,v);
save([data_path, 'bg.mat'],'bg')
% Train filters
H = train_filter(data_path,mask,ann,bg,'px',params,v);
H_hog = train_filter(data_path,mask,ann,bg,'hog',params,v);
save([data_path, 'filters.mat'],'H','H_hog','-v7.3')
% Tracking
tracker_out = tracker_detect(data_path,mask,bg,H,H_hog,params,v);
% Save output
save([data_path, 'tracker_out.mat'],'tracker_out','-v7.3')
end

