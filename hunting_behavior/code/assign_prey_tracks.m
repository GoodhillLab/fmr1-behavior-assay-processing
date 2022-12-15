function prey_coords = assign_prey_tracks(tracker_out,mask)
%POST_PREY Post processing on detected prey blobs
%   Assign tracks, filter spurious detection and smooth prey trajectories

% Get coordinates of arena limits
arena= bwboundaries(mask);
arena = arena{1};
arena = fliplr(arena);

% Loop over movies
for m=1:size(tracker_out,2)
    K = tracker_out(m).K;
    next_track_id = 1;
    tracks = struct(... % Initialise tracks
        'ID', {}, ...
        'Centroid', {}, ...
        'Area', {}, ...
        'Orientation', {}, ...
        'MajorAxisLength', {}, ...
        'MinorAxisLength', {}, ...
        'KalmanFilter', {}, ...
        'Detected', {}, ...
        'Age', {}, ...
        'k', []);
    completed_tracks =tracks;
    
    % Loop over frames
    for k = 1:K
        %fprintf('j = %d; k = %d\n',m,k)
        cost = zeros(length(tracks), ...
            size(tracker_out(m).blobs(k).Centroid,1));
        if ~isempty(tracker_out(m).blobs(k).Centroid) % skip if this frame had no detections
            for i = 1:length(tracks)
                % Predict centroid locations for existing tracks
                tracks(i).Centroid(k,:) = predict(tracks(i).KalmanFilter);
                
                % Correct for arena limits
                p = round(tracks(i).Centroid(k,1));
                q = round(tracks(i).Centroid(k,2));
                if p<1 || q<1 || p>tracker_out(m).w || ...
                        q>tracker_out(m).h || ~mask(q,p)
                    [~,idx] = min(vecnorm(arena-[p,q],2,2));
                    tracks(i).Centroid(k,:) = arena(idx,:);
                end
                
                % Compute assigment cost
                cost(i, :) = vecnorm(tracker_out(m).blobs(k).Centroid - ...
                    tracks(i).Centroid(k,:),2,2);
            end
        end
        
        % Assign detections to tracks
        [assignments, unassigned_tracks, unassigned_detections] = ...
            assignDetectionsToTracks(cost,10);
        
        % Update assigned tracks
        for i = 1:size(assignments, 1)
            idx_track = assignments(i, 1);
            idx_detect = assignments(i, 2);
            centroid = tracker_out(m).blobs(k).Centroid(idx_detect, :);
            
            % Correct the estimate of the object's location
            % using the new detection.
            tracks(idx_track).Centroid(k,:) = correct(tracks(idx_track).KalmanFilter, centroid);
            
            % Correct for arena limits
            p = round(tracks(i).Centroid(k,1));
            q = round(tracks(i).Centroid(k,2));
            if ~mask(q,p)
                [~,idx] = min(vecnorm(arena-[p,q],2,2));
                tracks(i).Centroid(k,:) = arena(idx,:);
            end
            
            % Replace predicted bounding box with detected
            % bounding box.
            tracks(idx_track).Centroid(k,:) = centroid;
            
            % Update visibility and age
            tracks(idx_track).Detected(k) = true;
            tracks(idx_track).Age = tracks(idx_track).Age + 1;
        end
        
        % Update unassigned tracks
        for i = 1:length(unassigned_tracks)
            idx = unassigned_tracks(i);
            tracks(idx).Detected(k) = false;
            tracks(idx).Age = tracks(idx).Age + 1;
        end
        
        % Create new tracks
        for i = 1:size(unassigned_detections, 1)
            idx = unassigned_detections(i);
            r_proc = [1e-3,1e-3];
            r_meas  = 10;
            
            % Create Kalman filter
            kalman_filter = configureKalmanFilter('ConstantVelocity', ...
                tracker_out(m).blobs(k).Centroid(idx, :), [2, 2], r_proc, r_meas);
            
            % Create a new track.
            newTrack = struct(...
                'ID', next_track_id, ...
                'Centroid', zeros(K,2,'single'), ...
                'Area', zeros(K,1,'single'), ...
                'Orientation', zeros(K,1,'single'), ...
                'MajorAxisLength', zeros(K,1,'single'), ...
                'MinorAxisLength', zeros(K,1,'single'), ...
                'KalmanFilter', kalman_filter, ...
                'Detected', false(K,1), ...
                'Age', 1, ...
                'k', []);
            
            % Add it to the array of tracks.
            tracks(end+1) = newTrack;
            next_track_id = next_track_id + 1;
            
            % Store tracking and blob data
            tracks(end).Centroid(k,:) = tracker_out(m).blobs(k).Centroid(idx, :);
            tracks(end).Area(k,:) = tracker_out(m).blobs(k).Area(idx, :);
            tracks(end).Orientation(k,:) = tracker_out(m).blobs(k).Orientation(idx, :);
            tracks(end).MajorAxisLength(k,:) = tracker_out(m).blobs(k).MajorAxisLength(idx, :);
            tracks(end).MinorAxisLength(k,:) = tracker_out(m).blobs(k).MinorAxisLength(idx, :);
            tracks(end).Detected(k) = true;
        end
        
        % Move completed tracks
        inactive_threshold = 500;
        complete = false(length(tracks),1);
        for i = 1:length(tracks)
            if ~any(tracks(i).Detected(max(1,(k-inactive_threshold)):k))
                % Add frame numbers then trim all time series to save space
                active = tracks(i).Centroid(:,1)>0;
                tracks(i).k = single(1:K);
                tracks(i).k = tracks(i).k(active);
                tracks(i).Centroid = tracks(i).Centroid(active,:);
                tracks(i).Area = tracks(i).Area(active);
                tracks(i).Orientation = tracks(i).Orientation(active);
                tracks(i).MajorAxisLength = tracks(i).MajorAxisLength(active);
                tracks(i).MinorAxisLength = tracks(i).MinorAxisLength(active);
                tracks(i).Detected = tracks(i).Detected(active);
                completed_tracks(end+1) = tracks(i);
                complete(i) = true;
            end
        end
        tracks = tracks(~complete);
        
        % Delete_intermittent_tracks
        age_threshold = 50;
        visibility_threshold = 0.8;
        intermittent = false(length(tracks),1);
        for i = 1:length(tracks)
            if tracks(i).Age==age_threshold
                visibility = sum(tracks(i).Detected((k-tracks(i).Age+1):k))/tracks(i).Age;
                if visibility < visibility_threshold
                    intermittent(i) = true;
                end
            end
        end
        tracks = tracks(~intermittent);
        
        
        %visualise_tracks(data_path,tracks,m,k,tracker_out)
    end
    % Move all tracks to completed
    for i = 1:length(tracks)
        % Add frame numbers then trim all time series to save space
        active = tracks(i).Centroid(:,1)>0;
        tracks(i).k = single(1:K);
        tracks(i).k = tracks(i).k(active);
        tracks(i).Centroid = tracks(i).Centroid(active,:);
        tracks(i).Area = tracks(i).Area(active);
        tracks(i).Orientation = tracks(i).Orientation(active);
        tracks(i).MajorAxisLength = tracks(i).MajorAxisLength(active);
        tracks(i).MinorAxisLength = tracks(i).MinorAxisLength(active);
        tracks(i).Detected = tracks(i).Detected(active);
        completed_tracks(end+1) = tracks(i);
    end
    prey_coords(m).tracks = rmfield(completed_tracks,'KalmanFilter');
end
end

function visualise_tracks(data_path,tracks,m,k,tracker_out)
files = dir(data_path);
files = files(~ismember({files.name},{'.','..'}));
files = files(contains({files.name},{'.seq'}));
file_path = fullfile(files(m).folder, files(m).name);
[f, ~] = seq_read(file_path,k);
imagesc(f,[0 127])
axis image
axis off
colormap('gray')
hold on
nTracks = length(tracks);
centroids = zeros(nTracks,2);
for i = 1:nTracks
    %if tracks(i).Active(k)
    centroids(i,:) = tracks(i).Centroid(k,:);
    labels(i) = cellstr(int2str(tracks(i).ID));
    %end
end


% f = mat2gray(f);
% f = insertText(f, centroids, labels);
% image(f)
hold on
scatter(centroids(:,1),centroids(:,2),4,lines(size(centroids,1)),'filled')
scatter(tracker_out(m).blobs(k).Centroid(:, 1),tracker_out(m).blobs(k).Centroid(:, 2),100,'y','MarkerEdgeAlpha',0.4)

hold off
ax = gca;
ax.XLim = [0,size(f,2)];
ax.YLim = [0,size(f,1)];
ax.Color = 'k';
ax.YDir = 'reverse';
ax.DataAspectRatio = [1,1,1];
ax.XTick = [];
ax.YTick = [];

drawnow()
end











