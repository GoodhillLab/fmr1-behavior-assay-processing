function x = kalman_smoother_2d(z,t,r_process,r_measurement)
%KALMAN_FILTER Summary of this function goes here
%   Detailed explanation goes here

% Parameters
m = 6; % dimensionality of the dynamical system model

% Initialisation
N = size(z,2); % Length of observations
x_predict = zeros(m,N);
x_estimate = zeros(m,N);
x_estimate(:,1) = [z(1,1); 0; 0; z(2,1); 0; 0];
P_predict = zeros(m,m,N);
P_estimate = zeros(m,m,N);
P_estimate(:,:,1) = eye(m);
R = [r_measurement,0;
    0,r_measurement];

% Measurement sensitivty matrix
H = [1, 0, 0, 0, 0, 0;
    0, 0, 0, 1, 0, 0];

% Forward pass
for n = 2:N
    dt = t(n)-t(n-1);
    if dt<0 % correct negative dt (this results from bad timestamps when the recordings have been stopped and restarted - which shouldn't happen, but sometimes does...)
        dt = 2; % not ideal to correct to 2 because of "teleporting fish" problem (not ideal to correct at all... better to split the moviesbetter to split the movies but this will do for now)
    elseif dt==0 % this probably happens as a result of clock sync issues in the high speed camera (obviously this will cause singularities and ust be corrected)
        dt = 1;
    elseif dt>1000 % if dt skips more than 1 second this is probably a recording restart by the experimenter and not just frame rate instability
        dt = 2; % not ideal to correct to 2 because of "teleporting fish" problem (not ideal to correct at all... better to split the movies but this will do for now)
    end
    F = [1, dt, dt^2/2, 0, 0, 0;
        0, 1, dt, 0, 0, 0;
        0, 0, 1, 0, 0, 0;
        0, 0, 0, 1, dt, dt^2/2;
        0, 0, 0, 0, 1, dt;
        0, 0, 0, 0, 0, 1];
    
    Q = [dt^4/4, dt^3/2, dt^2/2, 0, 0, 0;
        dt^3/2, dt^2, dt, 0, 0, 0;
        dt^2/2, dt, 1, 0, 0, 0;
        0, 0, 0, dt^4/4, dt^3/2, dt^2/2;
        0, 0, 0, dt^3/2, dt^2, dt;
        0, 0, 0, dt^2/2, dt, 1]*r_process;
    % Predict
    x_predict(:,n) = F*x_estimate(:,n-1);
    P_predict(:,:,n) = F*P_estimate(:,:,n-1)*F'+Q;
    % Update
    K = P_predict(:,:,n)*H'/(H*P_predict(:,:,n)*H'+R);
    x_estimate(:,n) = x_predict(:,n)+K*(z(:,n)-H*x_predict(:,n));
    P_estimate(:,:,n) = P_predict(:,:,n)-K*H*P_predict(:,:,n);
end

% Backward pass
for n = N-1:-1:1
    A = P_estimate(:,:,n)/P_predict(:,:,n+1);
    x_estimate(:,n) = x_estimate(:,n) + A*(x_estimate(:,n+1) - x_predict(:,n+1));
end

x = [x_estimate(1,:);x_estimate(4,:)];
end

