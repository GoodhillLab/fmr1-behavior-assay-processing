function event_ann = import_event_annotations(data_path)
%IMPORT_EVENT_ANN Imports the manual annotations csv

% Find file
files = dir(data_path);
files = files(~ismember({files.name},{'.','..'}));
files = files(contains({files.name},{'.csv'}));
file_path = fullfile(files(1).folder, files(1).name);

% Read event annotations
event_ann = readtable(file_path);
end

