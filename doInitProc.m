%% Do the initial processing on all of the folders

% Set up the top level directory
%topDir = '/Users/stephenholtz/local_data/sabatini/striatal_useable';
topDir = '~/local_data/sabatini/motor_cortex_useable';

% get folders
folders = dir([topDir filesep '2014*']);
overwriteFlag = 1;

for iFolder = 10:numel(folders)
    currStackLoc = fullfile(topDir,folders(iFolder).name);
    currStackName = dir(fullfile(currStackLoc,['reg_ch1','_*']));

    % crop the registered
    cropStack(fullfile(currStackLoc,currStackName(1).name),overwriteFlag);
    
    % pixel-by-pixel normalize the cropped -- this might not be necessary for subsequent analysis
    normalizeStack(fullfile(currStackLoc,['crop_' currStackName(1).name]),overwriteFlag);

    % max int the normalized
    makeMaxProj(fullfile(currStackLoc,['norm_crop_' currStackName(1).name]),overwriteFlag);
end

