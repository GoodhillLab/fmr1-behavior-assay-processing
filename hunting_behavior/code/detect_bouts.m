function  bouts = detect_bouts(fish_coords,tail_curve,params)
%DETECT_BOUTS Detects bout start and end frames from tail kinematics
%   Detailed explanation goes here

bout_thresh = params.bout_thresh;
min_bout_time = params.min_bout_time;
bout_max_freq = params.bout_max_freq;

bouts = struct([]);

for m=1:size(tail_curve,1)
    dt = diff(fish_coords(m).t);
    % Correct negative dt (this results from bad timestamps when the recordings have been stopped and restarted - which shouldn't happen, but sometimes does...)
    dt(dt<0) = 2;
    dt(dt>1000) = 2; % if dt skips more than 1 second this is probably a recording restart by the experimenter and not just frame rate instability
    samp_freq = 1/mean(dt/1000);
    n_seg = size(tail_curve{m},2); % number of tail segments
    % Compute angular velocity
    angular_velocity = diff(tail_curve{m},1,1);
    % Pad to set initial velocity to zero
    angular_velocity = padarray(angular_velocity,[1,0],'pre');
    % Take mean over last 20% of tail segments
    idx = round(n_seg*0.8)+1;
    angular_velocity = mean(angular_velocity(:,idx:end),2);
    angular_velocity = lowpass((angular_velocity),bout_max_freq,samp_freq,'Steepness',0.85); % Steepness 0.85 gives a smooth roll off
    tail_envelope = abs(hilbert(angular_velocity));
    % Threshold for bouts
    bout_flag = tail_envelope>bout_thresh;
    % Filter out short bouts
    bout_flag = filter_bouts(bout_flag,min_bout_time);
    % Extract start and end frames of all bouts in sequence
    frames = [];
    frames(:,1) = find(diff([0;bout_flag],1)==1);
    frames(:,2) = find(diff([bout_flag;0],1)==-1);
    bouts(m).flag = bout_flag;
    bouts(m).frames = frames;
end

end

function bout_flag = filter_bouts(bout_flag,min_bout_time)
%FILTER_BOUTS filters detected bouts to enforce a minimum activation time
%of min_time Detected outs shorter than min_time are replaced with zeros.

% Pad
bout_flag = padarray(bout_flag,[1,0]);

N = size(bout_flag,1);

% Minimum time
for w = 1:min_bout_time-1
    old = padarray(true(1,w),[0 1]);
    new = false(size(old));
    L = length(new);
    n = L;
while n<=N
    if all(bout_flag(n-L+1:n)==old')
        bout_flag(n-L+1:n) = new;
    end
    n = n+1;
end
end
% Trim
bout_flag = bout_flag(2:end-1);
end
