function tracker_out = tracker_detect(data_path,mask,bg,H,H_hog,params,v)
%TRACK_ALL Summary of this function goes here
%   Detailed explanation goes here

tracker_out = struct([]);

% Loop tracker over files
for j = 1:length(v)    
    [t,swim_bladder,swim_bladder_psr,eye_midpoint,eye_midpoint_psr, ...
        skeleton,blobs,K,w,h,bad_frame] = tracker(v(j),mask,bg(j), ...
        H,H_hog,params);
    tracker_out(j).t = t;
    tracker_out(j).swim_bladder= swim_bladder;
    tracker_out(j).swim_bladder_psr= swim_bladder_psr;
    tracker_out(j).eye_midpoint = eye_midpoint;
    tracker_out(j).eye_midpoint_psr = eye_midpoint_psr;
    tracker_out(j).skeleton = skeleton;
    tracker_out(j).blobs = blobs;
    tracker_out(j).K = K;
    tracker_out(j).w = w;
    tracker_out(j).h = h;
    tracker_out(j).bad_frame = bad_frame;
end
end

function [t,swim_bladder,swim_bladder_psr,eye_midpoint, ...
    eye_midpoint_psr,skeleton,blobs,K,w,h,bad_frame] = ...
    tracker(vv,mask,bg,H,H_hog,params)
sz = params.sz;
sz_mid = 385; % size of the tracking window for skeletonisation - this can be a static parameter
pow2 = 2.^(0:12);
zp = min(pow2(pow2>=sz));
[Qpsr,Ppsr] = ndgrid(1:zp,1:zp);

% Get image information and initialise reader
K = vv.NumFrames;
w = vv.Width;
h = vv.Height;

% GPU arrays
H = gpuArray(H);
H_hog = gpuArray(H_hog);

% Initialise output
t = zeros(K,1); % time elapsed from start of movie in ms
bad_frame = false(K,1); % flag for bad/corrupt frames (i.e. all pixels blank, bad timestamp)
swim_bladder = zeros(K,2);
swim_bladder_psr = zeros(K,1);
eye_midpoint = zeros(K,2);
eye_midpoint_psr = zeros(K,1);
skeleton = cell(K,1);
blobs(K) = struct();

t_init = 2;
t_null = -1;

for k=1:K
    % Get frame
    f = single(vv.readFrame());
    t_stamp = 2*k;
    t(k) = t_stamp-t_init;
    
    cond1 = any(all(f==0,2)); % blank rows
    cond2 = t_stamp==t_null; % bad timestamp
    if cond1 || cond2 % check for bad frames (i.e. blank rows, bad timestamp)
        bad_frame(k) = true;
        % forward-fill missing data
        if k>1
            swim_bladder(k,:) = swim_bladder(k-1,:);
            swim_bladder_psr(k) = swim_bladder_psr(k-1);
            eye_midpoint(k,:) = eye_midpoint(k-1,:);
            eye_midpoint_psr(k) = eye_midpoint_psr(k-1);
            skeleton(k) = skeleton(k-1);
            blobs(k) = blobs(k-1);
        end
    else
        % Foreground extraction
        fg = abs((f-bg.mean)./bg.std) > bg.thr;
        fg = fg & mask; % foreground mask
        fgfilt = fg & (f > params.thr); % foreground mask filtered for low intensity noise
        fgfilt = bwareaopen(fgfilt,9,4); % foreground mask filtered to remove small connected components (min area = 9 px, 4-connected)
        fm = bwareafilt(fgfilt,1,4); % fish mask
        fp = fgfilt & ~fm; % prey mask
        [Q, P] = find(fm == 1);
        p = round(mean(P));
        q = round(mean(Q));
        
        % Get cropped tracking window and foreground mask
        p0 = min(max(p-(sz-1)/2,1),w-sz+1);
        q0 = min(max(q-(sz-1)/2,1),h-sz+1);
        fc = f(q0:(q0+sz-1),p0:(p0+sz-1));
        fc = padarray(fc,[zp-sz,zp-sz],0,'post');
        fmc = fm(q0:(q0+sz-1), ...
            p0:(p0+sz-1));
        fmc = padarray(fmc,[zp-sz,zp-sz],0,'post');
        fc = fc.*fmc;
        
        % Correlation based tracking
        f_hog = fhog(fc, params.bin_size, params.n_orients);
        f_hog(:,:,end) = [];
        F = fft2(gpuArray(fc));
        F_hog = fft2(gpuArray(f_hog));
        G_hog = H_hog.*F_hog;
        G_hog = sum(G_hog,3);
        g_hog = real(ifft2(G_hog));
        G = H.*F;
        g = real(ifft2(G));
        g = g.*imresize(g_hog,[zp,zp]).*fmc;
        r1 = max(g(:,:,:,:,:,1),[],[1,2]);
        r2 = max(g(:,:,:,:,:,2),[],[1,2]);
        r = r1.*r2;
        [~,i] = max(r(:));
        [ia,is] = ind2sub([size(H,4),size(H,5)],i);
        gmax = g(:,:,:,ia,is,1);
        [rmax,v] = max(gmax(:));
        [q,p] = ind2sub([zp,zp],v);
        swim_bladder(k,:) = gather([p + p0,q + q0]); % tracking point
        slm = (2*params.sigma)^2<=(Ppsr-p).^2+(Qpsr-q).^2; % peak mask
        swim_bladder_psr(k) = gather((rmax-mean(gmax(slm)))/std(gmax(slm))); %psr
        gmax = g(:,:,:,ia,is,2);
        [rmax,v] = max(gmax(:));
        [q,p] = ind2sub([zp,zp],v);
        eye_midpoint(k,:) = gather([p + p0,q + q0]);% tracking point
        slm = (2*params.sigma)^2<=(Ppsr-p).^2+(Qpsr-q).^2; % peak mask
        eye_midpoint_psr(k) = gather((rmax-mean(gmax(slm)))/std(gmax(slm))); % psr
        
        % Skeletonise
        p = swim_bladder(k,1);
        q = swim_bladder(k,2);
        p0 = min(max(p-(sz_mid-1)/2,1),w-sz_mid+1);
        q0 = min(max(q-(sz_mid-1)/2,1),h-sz_mid+1);
        fgc = fg(q0:(q0+sz_mid-1), ...
            p0:(p0+sz_mid-1));
        fgc = bwareafilt(fgc,1,4); % fish mask
        fgc = bwmorph(fgc,'spur'); % smoothing 1
        fgc = imgaussfilt(double(fgc),2)>0.5; % smoothing 2
        fgc = imfill(fgc,'holes'); % fill holes
        sk = bwmorph(fgc,'thin',Inf); %  skeletonise
        [sky,skx] = find(sk);
        skx = skx + p0;
        sky = sky + q0;
        skeleton{k} = [skx,sky];
        
        % Prey blob detection
        blob_props = regionprops(fp,'Centroid','Area','MajorAxisLength', ...
            'MinorAxisLength','Orientation');
        blobs(k).Centroid = cat(1,blob_props.Centroid);
        blobs(k).Area = cat(1,blob_props.Area);
        blobs(k).MajorAxisLength = cat(1,blob_props.MajorAxisLength);
        blobs(k).MinorAxisLength = cat(1,blob_props.MinorAxisLength);
        blobs(k).Orientation = cat(1,blob_props.Orientation);
    end
end
end