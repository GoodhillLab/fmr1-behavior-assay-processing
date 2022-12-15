function [coordinateX,coordinateY,area,perimeter,slopeAngle, axisLong, axisShort] = minOuterRect(imageBinary,targetValue)
    if(nargin < 2)
        targetValue = 1;
    end
    if(targetValue == 1)
        targetValue = 0;
    else
        targetValue = 1;
    end
    if ~islogical(imageBinary)
        bw=im2bw(imageBinary);
    else
        bw = imageBinary;
    end
    [row,col]=find(bw==targetValue);
    [coorX,coorY,area,perimeter] = minboundrect(col,row,'a'); 
    sideA = sqrt((coorX(1) - coorX(2)).^2+(coorY(1)-coorY(2)).^2);
    sideB = sqrt((coorX(2) - coorX(3)).^2+(coorY(2)-coorY(3)).^2);
    if(sideA > sideB)
        slopeAngle = -atan((coorY(1)-coorY(2))./(coorX(1)-coorX(2)))/pi * 180;   % in degree
        axisLong = sideA;
        axisShort = sideB;
    else
        slopeAngle = -atan((coorY(3)-coorY(2))./(coorX(3)-coorX(2)))/pi * 180;   % in degree
        axisLong = sideB;
        axisShort = sideA;
    end             
   
coordinateX = coorX;
coordinateY = coorY;
end
