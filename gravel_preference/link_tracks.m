function D = link_tracks(T,init_T)
%LINK_TRACKS Links fragmented tracks
costOfNonAssignment = 1e6;
K = size(T{1},1);
D = cell(4,1);
UNASSIGNED = true(1,length(T));
for f = 1:4
    D{f} = nan(K,2);
    D{f}(1,:) = init_T(f,:);
end

fprintf('Progress: \n')
fprintf('%7.2f%%',0)
for k=2:K
    fprintf('\b\b\b\b\b\b\b\b%7.2f%%',k/K*100)
    % Check if track has data for this timestep
    for f = 4:-1:1
        no_track(f) = isnan(D{f}(k,1));
    end
    no_track = find(no_track);
    
    % Get candidate tracks
    candidate = [];
    for d = size(T,2):-1:1
        candidate(d) = ~isnan(T{d}(k,1));
    end
    candidate = find(candidate & UNASSIGNED);
    
    % Assign track if no track and close to track fragment at this time
    % compute cost matrix
    C = [];
    X = cell2mat(cellfun(@(x)x(k-1,:),D(no_track),'UniformOutput',false));
    Y = cell2mat(cellfun(@(x)x(k,:),T(candidate),'UniformOutput',false)');
    for i=size(X,1):-1:1
        x = X(i,:);
        for j=size(Y,1):-1:1
            y = Y(j,:);
            C(i,j) = sqrt(sum((x-y).^2));
        end
    end
    C(isnan(C))= inf;

    % assign tracks
    if ~isempty(C)
        [AT,UT,~] = assignDetectionsToTracks(C,costOfNonAssignment);
    else
        AT = [];
        UT = 1:length(no_track);
    end
    
    for j=1:size(AT,1)% assigned tracks
        z = T{candidate(AT(j,2))};
        z_end = k+find(isnan(z(k:end,1)),1)-1;
        if isempty(z_end)
            z_end = size(z,1);
        end
        D{no_track(AT(j,1))}(k:z_end,:) = z(k:z_end,:);
        UNASSIGNED(candidate(AT(j,2))) = false;
    end

    % forward fill unassigned tracks
    for j=1:length(UT)% assigned tracks
        D{no_track(UT(j))}(k,:) = D{no_track(UT(j))}(k-1,:);
    end
    
end
end

