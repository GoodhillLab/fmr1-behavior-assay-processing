function get_socialMeasures(path2Data,fishName)
    trackName = [path2Data,filesep,fishName,'.mat'];
    load(trackName,'fishTracking');
    fishid = [1,3,5,7];%%%only look at test fish
    factor = 47/floor(fishTracking.fishlim{1,8}(1,2)-fishTracking.fishlim{1,8}(1,1));% convert into mm
    SPI = zeros(1,4);
    StateSwap = zeros(1,4);
    SocialDuration = zeros(1,4);
for q = 1:4
    X = fishTracking.centreCoorX(:,fishid(q)).*factor;
    Y = fishTracking.centreCoorY(:,fishid(q)).*factor;
    X0 = fishTracking.centreCoorX(:,fishid(q)+1).*factor;
    Y0 = fishTracking.centreCoorY(:,fishid(q)+1).*factor;
    A = fishTracking.fishangle(:,fishid(q));
    Lim = fishTracking.fishlim{1,fishid(q)}.*factor;
%%% plot raw data
    i = X(:)~=0;
    X = X(i);
    Y = Y(i);
    X0 = X0(i);
    Y0 = Y0(i);
    [spi,swap,duration] = get_SPI(X,Y,Lim);
    title(spi);
    SPI(q) = spi;
    StateSwap(q) = swap;
    SocialDuration(q) = duration;
%%% plot location heat map
    xbound = linspace(Lim(1,1),Lim(1,2),21);
    ybound =  linspace(Lim(2,1),Lim(2,2),21);
    for j = 1:20
        yindex = Y(:) > ybound(j) & Y(:)<ybound(1+j);
        xval = X(yindex);
        edges1 = xbound;
        h1 = histogram(xval,edges1);
        xcounts = h1.Values;
        OUT(j,:) = xcounts;
    end    
%%% fish heading angle
    [N,~] = histcounts(A,0:20:360);
    heights = N/length(A);
    centers = 0+20/2:20:360-20/2;
    n = length(centers);
    w = centers(2)-centers(1);
    t = linspace(centers(1)-w/2,centers(end)+w/2,n+1);
    p = fix(n/2);
    dt = diff(t);
    Fvals = cumsum([0,heights.*dt]);
    F = spline(t, [0, Fvals, 0]);
    DF = fnder(F);  % computes its first derivative
    points = fnplt(DF);
    polarplot(points(2,:))
    angleHist(:,q) = points(2,:)';

%%% calculate the distance traveled    
    tempfc1 = [X Y;0 0];
    shift1 = circshift(tempfc1,1);
    TD1 = sqrt((tempfc1(:,1)-shift1(:,1)).^2+(tempfc1(:,2)-shift1(:,2)).^2);
    td = sum(TD1(2:end-1));
    travelDist(q) = td;
   
end
if ~isfield(fishTracking,'SPI') && isfield(fishTracking,'fishangle')    
    fishTracking.SPI = SPI;
    fishTracking.StateSwap = StateSwap;
    fishTracking.SocialDuration = SocialDuration;
    fishTracking.travelDist = travelDist;
    fishTracking.angelHist = angleHist;
    save(trackName,'fishTracking');
end


