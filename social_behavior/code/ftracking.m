function fishResult = ftracking(fileInd,fishfileName,path2Data,data)
frameInd = 1;
fishsizethrsh = data.fishTracking.Params.fishsizethrsh;
nFramesCollected = data.fishTracking.Params.nFramesCollected;
mData = data.fishTracking.Params.mData;
th = data.fishTracking.Params.th;
if fileInd == 1
    fileName = strcat(fishfileName, '_MMStack_Pos0.ome.tif');    
else
    fileName = strcat(fishfileName, '_MMStack_Pos0_', num2str(fileInd-1), '.ome.tif');
end

fo = imboxfilt(double(imread(strcat(path2Data,filesep,fileName),frameInd))./mData);
thrsh =  fo >= th;
thrsh = bwmorph(thrsh, 'close', Inf);
z = image2z(thrsh,fo,fishsizethrsh);

origCen = zeros(2,8);
oldfishAngle = zeros(1,8);
FISHLIM = data.fishTracking.fishlim;
[NewCen,NewAngle] = confirmFishID_frame1(origCen,oldfishAngle,z,FISHLIM);
fishResult.fishLength = z.fishlength;
fishResult.centreCoorX(frameInd,:) = NewCen(1,:); 
fishResult.centreCoorY(frameInd,:) = NewCen(2,:); 
fishResult.fishangle(frameInd,:) = NewAngle;
origCen = NewCen;
oldfishAngle = NewAngle;
frameInd = frameInd + 1;

% Select movie file: 
for j = 2:nFramesCollected(fileInd)
    f = imboxfilt(double(imread(strcat(path2Data,filesep,fileName),j))./mData);
    thrsh =  f >= th;
    thrsh = bwmorph(thrsh, 'close', Inf);
    z = image2z(thrsh,f,fishsizethrsh);
    [NewCen,NewAngle] = confirmFishID(origCen,oldfishAngle,z,FISHLIM);
    oldfishAngle = NewAngle;
    origCen = NewCen;
    fishResult.centreCoorX(frameInd,:) = NewCen(1,:); 
    fishResult.centreCoorY(frameInd,:) = NewCen(2,:); 
    fishResult.fishangle(frameInd,:) = NewAngle;
    frameInd = frameInd + 1;    
end
%     savename = strcat(fishfileName(1:end-5),'_',num2str(fileInd));
%     save(fullfile(fishRootFolder,savename),'fishResult');
    fprintf( 1 , [ '>> END tracking ',num2str(fileInd), '\n' ] );
end