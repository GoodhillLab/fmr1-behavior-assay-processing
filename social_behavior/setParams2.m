function setParams2(fishName,cond,path2Data)
warning('off','MATLAB:imagesci:tiffmexutils:libtiffWarning');
fishfileName = strcat(fishName,'_',cond);
trackName = [fishName,'.mat'];
load(fullfile(path2Data,trackName));
if ~isfield(fishTracking,'Params')
%%% gather prams

frameInterval = 5000; %%%
[nFramesCollected,fileListLen] = getnFrames2(path2Data,fishfileName);    

% Calculate the total number of frames in the collection of movies:
nFrames=sum(nFramesCollected);
fInd = 1;
for fileInd = 1:fileListLen
    
    % Determine the name of the file:
    if fileInd == 1
        fileName = strcat(fishfileName, '_MMStack_Pos0.ome.tif');
    else
        fileName = strcat(fishfileName, '_MMStack_Pos0_', num2str(fileInd-1), '.ome.tif');
    end
    
    for i=1:frameInterval:nFramesCollected(fileInd)
        framesCollection(:,:,fInd) = imread(strcat(path2Data,fileName),i);
        fInd=fInd+1;
    end
    fprintf( 1 , [ '>> END collect frames ',num2str(fileInd), '\n' ] );
end

% Calculate mean intensity image:
fileName = strcat(fishfileName, '_MMStack_Pos0.ome.tif');
data = double(framesCollection);
mData = (mean(data, 3));
fo = imboxfilt(double(imread(strcat(path2Data,filesep,fileName),1))./mData);
% get the thrshold value
possibleThresh = 1.2:0.05:1.5;
th = possibleThresh(7); %%% previously tested good threshold level
thrsh =  fo >= th;
fishsizethrsh = 100;
fishTracking.Params.nFramesCollected = nFramesCollected;
fishTracking.Params.fileListLen = fileListLen;
fishTracking.Params.thrshImg = thrsh;
fishTracking.Params.fishsizethrsh = fishsizethrsh; 
fishTracking.Params.originImg = fo;
fishTracking.Params.mData = mData;
fishTracking.Params.th = th;
save(fullfile(path2Data,fishName),'fishTracking');
end
fprintf( 1 , [ '>> END Param ' '\n' ] );
end