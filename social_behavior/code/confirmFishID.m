function [NewCen,NewAngle] = confirmFishID(oldCen,oldfishAngle,z,FishLim)
    newfishAngle = z.angle;
    newCen = z.centerCoor;
    NewCen = oldCen;
    NewAngle = oldfishAngle;
    IN = zeros(1,length(newCen));
    for n = 1:length(FishLim)
        fishlim = FishLim{n};
        for nn = 1:length(newCen)
            bb = newCen(:,nn);
            in = inpolygon(bb(1),bb(2),[fishlim(1,1),fishlim(1,1),fishlim(1,2),fishlim(1,2),fishlim(1,1)],...
                [fishlim(2,1),fishlim(2,2),fishlim(2,2),fishlim(2,1),fishlim(2,1)]); 
            IN(nn) = in;
        end   
        id = find(IN(:)==1);
        lenid = length(id);
        if id
            if lenid>1               
                D = [];
                for nnn = 1:lenid  
                    d = norm(NewCen(:,n)-newCen(:,id(nnn)));
                    D = [D,d];
                end          
                nid = D(:)==min(D);
                NewAngle(n) = newfishAngle(id(nid));
                confirmedCen = newCen(:,id(nid));
                NewCen(:,n) = confirmedCen;
            else
                NewAngle(n) = newfishAngle(id);
                confirmedCen = newCen(:,id);
                NewCen(:,n) = confirmedCen;
            end
        end
%          plot(confirmedCen(1),confirmedCen(2),'.','MarkerSize',12);
    end          

