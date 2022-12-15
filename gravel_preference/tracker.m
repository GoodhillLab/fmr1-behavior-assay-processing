function z = tracker(data_path,px_thr,gpu,vis)
% Setup reader
files = dir(fullfile(data_path,'*.mp4'));
files = files(~ismember({files.name},{'.','..','output.mp4'}));
fpath = fullfile(data_path,files.name);
fprintf('Reading video details...')
v = VideoReader(fpath);
K = v.Duration*v.FrameRate;
width = v.Width;
height = v.Height;
fprintf(' Done.\n\n')

% Initialise bg
bg_win_len = 100;
bg_step = 400;
B = zeros([height,width,bg_win_len],'single');
if gpu
    B = gpuArray(B);
end
j = 1;
fprintf('Initialising background: \n')
fprintf('%5.1f%%',0)
for k=1:bg_win_len*bg_step
    fprintf('\b\b\b\b\b\b%5.1f%%',k/(bg_win_len*bg_step)*100)
    if mod(k,bg_step)==1
        v.CurrentTime = (k-1)/v.FrameRate; % Reading spaced frames is slow
        frame = readFrame(v);
        B(:,:,j) = frame(:,:,1);
        j = j + 1;
    end
end
fprintf('Done.\n');

% Initialise output
z = cell(K,1);

fprintf('Progress: \n')
fprintf('%7.2f%%',0)

% Re-initialise reader for tracking
v = VideoReader(fpath);

% Initialise background model index counter
j = 0;

% Background model threhsold
thr=2;

% Set up temporal filtering
%   To deal with noisy fg detections, a pixel is only foreground if it is
%   foreground in the majority of previous frames (median) for a window of
%   lengh temp_filt_win_size. Must be odd because we want a logical out
%   (i.e. avoiding ties).
temp_filt_win_size = 3;
F = zeros([height,width,temp_filt_win_size],'double');
if gpu
    F = gpuArray(F);
end
temp_filt_start_counter = 1;

% Track
for k=1:K
    fprintf('\b\b\b\b\b\b\b\b%7.2f%%',k/K*100)
    % Get frame
    frame = readFrame(v);
    f = frame(:,:,1);
    if gpu
        f = gpuArray(f);
    end
    
    % Update backgound
    if mod(k,bg_step)==1
        B(:,:,j+1) = f;
        j = mod(j+1,bg_win_len);
        mu = mean(B,3);
        sig = std(B,[],3);
        % Use std to set agarose to bg
        edge = gpuArray(imbinarize(gather(mu)/255));
        sig(edge) = 1e6;
    end
    f = double(f);
    f = f.*(f>=px_thr);
    
    % Foreground extraction
    F(:,:,mod(k,temp_filt_win_size)+1) = (f-mu)./sig > thr;
    % If F has not been filled then don't take median - just take the fg
    % estimate
    if temp_filt_start_counter<temp_filt_win_size
        fg = F(:,:,mod(k,temp_filt_win_size)+1);
        temp_filt_start_counter = temp_filt_start_counter + 1;
    else
        fg = sum(F,3)>=ceil(temp_filt_win_size/2);
    end
    
    if gpu
        fg = gather(fg);
    end
    fg = bwareaopen(fg,36,8);
    
    % Smoothing
    if gpu
        fg = gpuArray(fg);
    end
    fg = double(fg);
    fg = imgaussfilt(fg,8)>0.1;
    fg = fg>0.1;
    
    % Filter
    if gpu
        fg = gather(fg);
    end
%     fg = bwareaopen(fg,100,4);
    fg = bwareafilt(fg,[100,10000],4);

   
    % Prey blob detection
    lbl = labelmatrix(bwconncomp(fg));
    lbl(edge) = 0; % exclude any pixels labelled as edge of arena
    % Keep top four blobs by mean brightness of 10 brightest pixels
    n_blobs = max(lbl,[],'all');
    brightness = [];
    if n_blobs>4
        for j=1:n_blobs
            px_values = f(lbl==j);
            if size(px_values,1)>10
                px_values = sort(px_values,'descend');
                px_values = px_values(1:10);
            end
            brightness(j) = gather(mean(px_values));
        end
        [~,blob_idx] = sort(brightness,'descend');
        for j=5:n_blobs
            lbl(lbl==blob_idx(j)) = 0;
        end
    end
    
    
    blob_props = regionprops(lbl,'Centroid');
    
    
    
    z(k) = {cat(1,blob_props.Centroid)};
    
    % Visualise tracking in real time
    if vis
        if k==1
            plt = imshowpair(frame(:,:,1),fg>0);
            hold on
            ax = gca;
            ax.DataAspectRatio = [1,1,1];
            drawnow
        elseif mod(k,100)==0
            C = imfuse(frame(:,:,1),fg>0);
            set(plt,'CData',C);
            drawnow
        end
    end
end
fprintf('Done.\n');
end