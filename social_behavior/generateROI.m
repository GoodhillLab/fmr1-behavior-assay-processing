function fishTracking = generateROI(fishName,path2Data)

fileList = dir(path2Data);
if fileList(1).name(1) == '.'
    fileList = fileList(3:end);
    if fileList(end).name(1) == 'T'
        fileList = fileList(1:end-1);
    end   
    if fileList(end).name(end) == 't'
        fileList = fileList(1:end-1);
    end 
end
fileName = strcat(fishName, '_MMStack_Pos0.ome.tif');
firstFrame = readTiff(strcat(path2Data,'\',fileName));
% Get the ROI
h1 = figure();
imagesc(firstFrame)
hold on
[~,rect1] = imcrop(h1);
fish1lim1 = [rect1(1),rect1(1)+rect1(3);rect1(2),rect1(2)+rect1(4)];
[~,rect2] = imcrop(h1);
fish1lim2 = [rect2(1),rect2(1)+rect2(3);rect2(2),rect2(2)+rect2(4)];
[~,rect3] = imcrop(h1);
fish1lim3 = [rect3(1),rect3(1)+rect3(3);rect3(2),rect3(2)+rect3(4)];
[~,rect4] = imcrop(h1);
fish1lim4 = [rect4(1),rect4(1)+rect4(3);rect4(2),rect4(2)+rect4(4)];
[~,rect5] = imcrop(h1);
fish1lim5 = [rect5(1),rect5(1)+rect5(3);rect5(2),rect5(2)+rect5(4)];
[~,rect6] = imcrop(h1);
fish1lim6 = [rect6(1),rect6(1)+rect6(3);rect6(2),rect6(2)+rect6(4)];
[~,rect7] = imcrop(h1);
fish1lim7 = [rect7(1),rect7(1)+rect7(3);rect7(2),rect7(2)+rect7(4)];
[~,rect8] = imcrop(h1);
fish1lim8 = [rect8(1),rect8(1)+rect8(3);rect8(2),rect8(2)+rect8(4)];
fishROI = {fish1lim1,fish1lim2,fish1lim3,fish1lim4,fish1lim5,fish1lim6,fish1lim7,fish1lim8};
close(h1)

fishTracking.fishlim = fishROI;
fishTracking.imageSize = size(firstFrame);
end