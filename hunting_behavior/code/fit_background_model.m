function bg = fit_background_model(data_path,N,mask,v)
%FIT_BACKGROUND_MODEL Compute a Gaussian background model for each pixel
%   mdl = fit_background_model(data_path,N,mask) returns a pixel-wise
%   Gaussian background model using data from N equi-spaced frames over all
%   movies in the folder data_path

bg = struct([]);

% Get total number of frames in the assay
for m = 1:length(v)
    K = v(m).NumFrames;
    width = v(m).Width;
    height = v(m).Height;
    
    % Get frame stack
    f = zeros([height,width,N],'double');
    idx = round(linspace(1,K,N));
    for n = progress(1:N)
        k = idx(n);
        f(:,:,n) = double(v(m).read(k));
        while all(f(:,:,n)==0) % if this is a bad frame (i.e. all zeros) then randomly resample until a good frame is found
            k = randi(K);
            f(:,:,n) = double(v(m).read(k));
        end
    end
    % Estimate mean and std
    b1_estimate = mean(f,3);
    c1_estimate = std(f,[],3);
    a1_estimate = normpdf(0,0,c1_estimate)*N;
    bg_mean = zeros(height,width);
    bg_std = zeros(height,width);
    Lower = [0, 0, 0];
    Upper = [N, 255, 255];
    for i = 1:height
        J = find(mask(i,:));
        parfor j = J
            if(b1_estimate(i,j)>0 && c1_estimate(i,j)>0)
                [pixelCounts,pixelIntensity] = histcounts(f(i,j,:),0:1:256);
                % Fit
                mdl = fit(pixelIntensity(1:end-1)',pixelCounts', ...
                    'gauss1', ...
                    'Lower',Lower, ...
                    'Upper',Upper, ...
                    'StartPoint',[a1_estimate(i,j),b1_estimate(i,j), ...
                    c1_estimate(i,j)]);
                bg_mean(i,j) = mdl.b1;
                bg_std(i,j) = mdl.c1/sqrt(2);
            end
        end
    end
    bg(m).mean = single(bg_mean);
    bg(m).std = single(bg_std);
    bg(m).thr = single(3); % static parameter
end
end

