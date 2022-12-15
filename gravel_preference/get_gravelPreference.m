function [gravel_pref,distance] = get_gravelPreference(tracks,boundary)
gravel_pref = zeros(1,4);
distance = zeros(1,4);
for d=1:4
    x = tracks{d}(:,1);
    y = tracks{d}(:,2);
    a = boundary(1);
    b = boundary(2);
    on_gravel = (y-b)/a<x;
    gravel_pref(d) = mean(on_gravel);
    distance(d) = sum(vecnorm(diff([x,y],1,1),2,2));
end
end