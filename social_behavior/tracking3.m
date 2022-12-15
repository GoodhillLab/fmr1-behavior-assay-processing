function tracking3(fishName,cond,path2Data)
fishfileName = strcat(fishName,'_',cond);
trackName = [path2Data,filesep,fishName,'.mat'];

myCluster = parcluster('local');
parpool(myCluster,4);
poolobj = gcp;

addAttachedFiles(poolobj,trackName)
data = load(trackName,'fishTracking');
fileListLen = data.fishTracking.Params.fileListLen;
parfor fileInd = 1:fileListLen
% for fileInd = 1:fileListLen
    FishTrack(fileInd) = ftracking(fileInd,fishfileName,path2Data,data);
end
    savename = strcat(fishName,'_p');
    save(fullfile(path2Data,savename),'FishTrack');
    fprintf( 1 , [ '>> END '  '\n' ] );
end