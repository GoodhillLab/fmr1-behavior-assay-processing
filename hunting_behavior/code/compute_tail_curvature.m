function tail_curve = compute_tail_curvature(fish_coords,tail_coords)
%COMPUTE_TAIL_CURVATURE Computes the tail curvature

tail_curve = cell(size(fish_coords,2),1);

for m=1:size(fish_coords,2)
    % Compute heading angle
    x1 = fish_coords(m).swim_bladder(:,1);
    y1 = fish_coords(m).swim_bladder(:,2);
    x2 = fish_coords(m).eye_midpoint(:,1);
    y2 = fish_coords(m).eye_midpoint(:,2);
    ha = atan2(y2-y1,x2-x1);
    % Compute angle of each segment (i.e. tangent to the curve)
    x = squeeze(tail_coords{m}(:,1,:));
    y = squeeze(tail_coords{m}(:,2,:));
    dx = -diff(x,1,2);
    dy = -diff(y,1,2);
    tail_curve{m} = atan2(dy,dx);
    % Align to heading angle
    tail_curve{m} = tail_curve{m} - ha;
    % Convert to degrees
    tail_curve{m} = rad2deg(tail_curve{m});
    % Wrap to 180
    tail_curve{m} = wrapTo180(tail_curve{m});
    % Unwrap to +/-360 (because a rotation >180 to the left is different
    % from a rotation >180 to the right)
    for i = 2:size(tail_curve{m},2)
        dtheta = [tail_curve{m}(:,i) - tail_curve{m}(:,i-1), ...        
        tail_curve{m}(:,i) - tail_curve{m}(:,i-1) + 360, ...
        tail_curve{m}(:,i) - tail_curve{m}(:,i-1) - 360];
        [~,idx] = min(abs(dtheta),[],2);
        idx = sub2ind(size(dtheta),(1:size(dtheta,1))',idx);
        tail_curve{m}(:,i) = tail_curve{m}(:,i-1) + dtheta(idx);
    end
end
end

