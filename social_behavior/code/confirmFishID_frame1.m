function [NewCen,NewAngle,FishLen] = confirmFishID_frame1(oldCen,oldfishAngle,z,FishLim)
    newfishAngle = z.angle;
    newCen = z.centerCoor;
    NewCen = oldCen;
    NewAngle = oldfishAngle;
    IN = zeros(1,length(newCen));
    FishLen = zeros(1,length(oldCen));
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
                    d = sum(z.fishshape{1,nnn}(:));
                    D = [D,d];
                end          
                nid = D(:)==max(D);
                NewAngle(n) = newfishAngle(id(nid));
                confirmedCen = newCen(:,id(nid));
                NewCen(:,n) = confirmedCen;
                FishLen(n) = z.fishlength(id(nid));
            else
                NewAngle(n) = newfishAngle(id);
                confirmedCen = newCen(:,id);
                NewCen(:,n) = confirmedCen;
                FishLen(n) = z.fishlength(id);
            end
        end
%         plot(confirmedCen(1),confirmedCen(2),'.','MarkerSize',12);
    end
 
                                             
                                              