function [nFramesCollected,fileListLen] = getnFrames2(path2RawData,fishfileName)    
% metafileroot = ['/fileserver/groups/microscopy/_User\ Folder/Zhu.I/socialbehaviourassay/Umaze/NewChamber/'];
% metafileroot = ['\\home.qbi.uq.edu.au\group_microscopy\_User Folder\Zhu.I\socialbehaviourassay\Umaze\NewChamber\'];
metafile = [path2RawData,fishfileName,'_MMStack_Pos0_metadata.txt'];
str  = fileread(metafile);
expression1 = '"FileName": (.+?),';
tokens1  = regexp( str , expression1, 'tokens') ;
for n = 1:length(tokens1)
    name = cell2mat(tokens1{1,n});
    i1 = strfind(name,'ome');
    i2 = strfind(name,'Pos0_');
    if ~isempty(i2)
        id = name(i2+5:i1-2);
        index(n) = str2double(id);
    else
        index(n) = 0;
    end
end
fileListLen = length(unique(index));
for fileInd = 1:fileListLen
    nFramesCollected(fileInd) = sum(index(:)==(fileInd-1));
end
end