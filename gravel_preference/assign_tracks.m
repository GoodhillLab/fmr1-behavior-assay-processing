function T = assign_tracks(z,init_T)
% Performs track assignment for F sets of coordinates by minimum euclidean
% distance

K = size(z,1);

% Parameters
costOfNonAssignment = 10;
len_min = 10; % 0.1 seconds

fprintf('Progress: \n')
fprintf('%7.2f%%',0)

for f = 1:4
    T{f} = nan(K,2);
    T{f}(1,:) = init_T(f,:);
    LEN(f) = 1;
end


for k=2:K
    % Progress meter
    fprintf('\b\b\b\b\b\b\b\b%7.2f%%',k/K*100)
    
    % get tracks
    nT = length(T);
    
    % compute cost matrix
    C = [];
    for t=nT:-1:1
        for b=size(z{k},1):-1:1
            C(t,b) = sqrt(sum((T{t}(k-1,:)-z{k}(b,:)).^2));
        end
    end
    C(isnan(C))= inf;

    % assign tracks
    [AT,UT,UD] = assignDetectionsToTracks(C,costOfNonAssignment);
    for j=1:min(size(AT,1),size(z{k},1)) % assigned tracks
        T{AT(j,1)}(k,:) = z{k}(AT(j,2),:);
        LEN(AT(j,1)) = LEN(AT(j,1)) + 1;
    end
    
    % Delete short tracks
    idx = [];
    for j=size(UT,1):-1:1 % unassigned tracks
        if LEN(UT(j))<len_min
            idx = [idx,UT(j)];
        end
    end
    T(idx) = [];
    LEN(idx) = [];
    
    % Create new tracks for unassigned detections
    for j=1:size(UD,1)
        T = [T,{nan(K,2)}];
        T{end}(k,:) = z{k}(UD(j),:);
        LEN = [LEN,1];
    end
    
end

end