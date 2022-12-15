function tail_coords = smooth_tail(tracker_out,fish_coords,params)
%POST_PROCESSING Smooth fish trajectory and extract tail from skeleton
%   Post processing on the tracked fish coordinates and skeleton.

tail_coords = cell(size(tracker_out,2),1);
n_points = params.n_tail_points;

for j=1:size(tracker_out,2)
    K = tracker_out(j).K;
    tail_coords{j} = zeros(K,2,n_points,'single');
    % Skeleton processing
    for k = 1:K
        %fprintf('j = %d; k = %d\n',j,k)
        sk = tracker_out(j).skeleton{k};
        x0 = min(sk(:,1))-1;
        y0 = min(sk(:,2))-1;
        w = max(sk(:,1))-x0;
        h = max(sk(:,2))-y0;
        sk = sk-[x0,y0];
        xswim = fish_coords(j).swim_bladder(k,1)-x0;
        yswim = fish_coords(j).swim_bladder(k,2)-y0;
        xeye = fish_coords(j).eye_midpoint(k,1)-x0;
        yeye = fish_coords(j).eye_midpoint(k,2)-y0;
        [~,idx] = min(vecnorm(sk-[xeye,yeye],2,2));
        BW = full(sparse(sk(:,2),sk(:,1),1,h,w))>0;
        D1 = bwdistgeodesic(BW,sk(idx(1),1),sk(idx(1),2));
        % Find nearest neighbour to swim bladder that is outside of the
        % circular region around the eye mindpoint with radius=|eye_midpoint-swim_bladder|
        r = norm([xeye,yeye]-[xswim,yswim]);
        idx = vecnorm(sk-[xeye,yeye],2,2)>r+10; % the +10px is to remove the portion of the skeleton immediately behind the swim bladder. This portion of the body is still rigid (more or less) and the skeletonisation does not always align well with the swim bladder point. Later in this function linear interpolation is used to include the swim bladder point in the skeleton.
        sktmp = sk(idx,:);
        [~,idx] = min(vecnorm(sktmp-[xswim,yswim],2,2));
        if ~isempty(idx) % if there exists detected skeleton outside of the radius around the eye-midpoint
            % Remove head end of skeleton
            idx = find(all(sk==sktmp(idx(1),:),2),1);
            BW = D1>=D1(sk(idx,2),sk(idx,1));
            BW = bwareafilt(BW,1,8); % Filter to keep only the largest remaining component (need this to remove fins in some frames)
            [row,col] = find(BW);
            if size(BW,1)==1 % MATLAB has a wierd behaviour for the output of 'find' when the input array has only 1 row. For arrays with more than one row, the [row,col] output is a pair of column vectors, otherwise it it a pair of row vectors... bizarre. This is a fix for that problem.
                row = row';
                col = col';
            end
            sk = [col,row];
            % Prune skeleton
            [~,idx] = min(vecnorm(sk-[xswim,yswim],2,2));
            D1 = bwdistgeodesic(BW,sk(idx(1),1),sk(idx(1),2));
            [v,idx] = max(D1(:));
            D2 = bwdistgeodesic(BW,idx);
            BW = (D1+D2)==v;
            BW = bwmorph(BW,'thin','inf'); % Re-thinning is needed (segments of thickness > 1px can arise from pruning)
            [row,col] = find(BW);
            sk = [col,row];
        else
            sk = [];
        end
        if size(sk,1)>2
            % Boundary trace
            [~,idx] = min(vecnorm(sk-[xswim,yswim],2,2));
            sk = fliplr(bwtraceboundary(BW,[sk(idx(1),2),sk(idx(1),1)],'N',8,sum(BW,'all')));
            % Linear interpolation to add the swim bladder
            q = [xswim,yswim; sk];
            cumlen = cumsum(vecnorm(diff(q,1),2,2));
            xi = linspace(0,cumlen(end),300); % 300 is a static parameter which should provide sufficiently fine interpolation for this stage of interpolation
            sk= interp1([0; cumlen],q,xi,'linear');
            % Smooth with Savitzky–Golay filter
            windowWidth = 151; % Approx half the length of the tail
            polynomialOrder = 3; % 3 is a static parameter that should provide enough flexibility to fit the tail midline
            smoothX = sgolayfilt(sk(:,1), polynomialOrder, windowWidth);
            smoothY = sgolayfilt(sk(:,2), polynomialOrder, windowWidth);
            q = [smoothX,smoothY];
            % Interpolate for evenly spaced points
            cumlen = cumsum(vecnorm(diff(q,1),2,2));
            xi = linspace(0,cumlen(end),n_points);
            sk= interp1([0; cumlen],q,xi,'linear');
            % Reset origin to frame
            sk = sk+[x0,y0]; 
            tail_coords{j}(k,:,:) = sk';
        end
        %visualise_results(fish_coords,j,k,tail_coords) % For debugging
    end
end
end

function visualise_results(fish_coords,j,k,skeleton)
        data_path = 'D:\feeding_assay_processing\20190618-f1\'; % Temp for debugging

        % Find files
        files = dir(data_path);
        files = files(~ismember({files.name},{'.','..'}));
        files = files(contains({files.name},{'.seq'}));
        file_path = fullfile(files(j).folder, files(j).name);
        [f, ~] = seq_read(file_path,k);
        imagesc(f,[0 127])
        hold on
        scatter(fish_coords(j).eye_midpoint(k,1), ...
            fish_coords(j).eye_midpoint(k,2),4,'r')
        hold on
        scatter(fish_coords(j).swim_bladder(k,1), ...
            fish_coords(j).swim_bladder(k,2),4,'c')
        sk = squeeze(skeleton{j}(k,:,:));
        if ~all(sk==0)
            scatter(sk(1,:),sk(2,:),1,'g')
        end
        ax = gca;
        ax.Color = 'k';
        ax.XLim = [0 1024];
        ax.YLim = [0 1024];
        ax.DataAspectRatio = [1,1,1];
        ax.XTick = [];
        ax.YTick = [];
        ax.YDir = 'reverse';
        axis image
        axis off
        colormap('gray')
        drawnow
        hold off
    end

