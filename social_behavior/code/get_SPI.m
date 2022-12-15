function [spi,swap,duration] = get_SPI(X,Y,Lim)
    sx = min(Lim(1,:))+ (max(Lim(1,:))-min(Lim(1,:))).*0.63;
    sy = min(Lim(2,:))+ (max(Lim(2,:))-min(Lim(2,:))).*0.64;
    nx = min(Lim(1,:))+ (max(Lim(1,:))-min(Lim(1,:))).*0.37;
    movieLen = length(X);
    spf = 0;nspf = 0;
    for nn = 1:movieLen
        x = X(nn);
        y = Y(nn);
        if x>=sx && y<=sy
            spf = spf+1;
        end  
        if x<=nx && y<=sy
            nspf = nspf+1;
        end  
    end
    spi = (spf-nspf)/movieLen; 
    
    sxindex = find(X(:)>=sx);
    yindex = find(Y(:)<=sy);
    index1 = intersect(sxindex,yindex);
    if ~isempty(index1)
        D = diff([0,diff(index1')==1,0]);
        first = index1(D>0);
        last = index1(D<0);
        swap = length(first);
        duration = mean(last-first);
    else
        swap = 0;
        duration = 0;
    end

end