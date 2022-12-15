function [z]= image2z(thrshimg,orgimg,fishsizethrsh)
ImgFiltered = double(thrshimg);
temp = size(ImgFiltered);
X = repmat(1:temp(2),[temp(1) 1]);
Y = repmat((1:temp(1))',[1 temp(2)]);

manchas=bwconncomp(ImgFiltered);
tams=cellfun(@(x) length(x),manchas.PixelIdxList);
listapixels=manchas.PixelIdxList(tams > fishsizethrsh);

numFishes = 0;
z = struct('centerCoor',[],'imageCroped',[]);
if length(listapixels)>numFishes
    numFishes = length(listapixels);
end
z.numFishes = numFishes;
for c_buenos=1:length(listapixels)

    imgFilter2D=false(manchas.ImageSize);
    imgFilter2D(listapixels{c_buenos})=true;
%             ind=find(imgFilter2D);       
    x = X(imgFilter2D);
    y = Y(imgFilter2D);
    lim=[min(x) max(x) min(y) max(y)];
    z.fishshape{c_buenos}=imgFilter2D;

    [coorX,coorY,~,~,theta,axisLong,axisShort]=minOuterRect(imgFilter2D,0);
    z.centerCoor(:,c_buenos)= [sum(coorX(1:4,:))/4,sum(coorY(1:4,:))/4];     
    if axisLong/axisShort >2               
        [nRow,nCol,~] = size(imgFilter2D);
        if theta < 45 && theta>-45        
            nSumLeft = sum(sum(imgFilter2D(:,1:floor(z.centerCoor(1,c_buenos))),1),2);                         
            nSumRight = sum(sum(imgFilter2D(:,[ceil(z.centerCoor(1,c_buenos)):nCol]),1),2);
            theta = mod(theta+360,360);
            if(nSumLeft > nSumRight)    % left
                if theta < 90
                    theta = theta + 180;
                elseif theta > 270
                    theta = theta - 180;
                end
            else                        % right
                if theta >= 180 && theta < 270
                    theta = theta-180;
                elseif theta < 180 && theta > 90
                    theta = theta +180;
                end
            end
        else 
            nSumUp = sum(sum(imgFilter2D(1:floor(z.centerCoor(2,c_buenos)),:),1),2);
            nSumDown = sum(sum(imgFilter2D(ceil(z.centerCoor(2,c_buenos)):nRow,:),1),2);
            theta = mod(theta+360,360);
            if(nSumUp > nSumDown)   % up
                if theta > 180
                    theta = theta - 180;
                end
            else                    % down
                if theta < 180
                    theta = theta + 180;
                end
            end
        end

    else
        if theta <0
            theta = abs(atan((coorY(3)-coorY(1))./(coorX(3)-coorX(1)))/pi * 180);   % in degree
        end
        
    end
    z.angle(c_buenos)=theta;
    z.fishlength(c_buenos) = axisLong;
end