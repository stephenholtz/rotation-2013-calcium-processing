% Add some daq information to the summary struct sC
% use the movement of fast and slow galvos to find
% new frames (hard-coded/doesn't  check which is which)
%
% SLH

addpath(genpath('~/grad_repos/calcium-processing'));

topDir = '~/local_data/sabatini/motor_cortex_useable';
folders = dir([topDir filesep '2014*']);

for folderNum = 1%:numel(folders);
    fp = fullfile(topDir,folders(folderNum).name);
    disp(fp);

    vn = 'sortedCells.mat';
    fn = fullfile(fp,vn);
    load(fn);
     
    % Extract the AD stream from the saved mat files, kinda hacky
    % but internal structure variable naming was silly
    % Gives a warning, but it is okay (some scanimage peculularity)
    for iChan = [0 2 3]
        adChFn = dir(fullfile(fp,['AD' num2str(iChan) '*'])); 
        load(fullfile(fp,adChFn(1).name));
        tmpWhos = whos(['AD' num2str(iChan) '*']);
        tmpEvalOut = eval(tmpWhos(1).name);
        AD.(['ch' num2str(iChan)]) = tmpEvalOut;  
    end
    clear tmp*  adChFn vn

    %% Calculate frame rate information etc.,
    % ch3 should be the slow (frame rate) info and ch2 the fast
    fastImgInds = find(abs(diff(AD.ch2.data)) > .1);
    lastImgInd =  fastImgInds(end);
    % correct for the case when the first imaging ind is not right at the beginning (i.e. when a prior session contaminates... a terrible terrible hack
    lateStartInds = find(diff(fastImgInds) > 10*mean(diff(fastImgInds)));
    if ~isempty(lateStartInds) && numel(lateStartInds) > 1
        figure;
        plot(AD.ch2.data);
        hold all
        indToUse = input('What is the start point? ');
        startImgInd = indToUse;
    else
        startImgInd = fastImgInds(1);
    end
    newFrames = (AD.ch3.data(startImgInd:end)>.5);
    newFrames = [0*ones(1,startImgInd) (diff(newFrames) > 0)];
    frameInd = cumsum(newFrames);

    % seconds per frame
    frameDur = diff(find(diff(frameInd)>0));
    frameDur = mode(frameDur(2:end-1));

    sC.AD = AD;
    sC.frameInd = frameInd;
    sC.frameDur = frameDur;

    save(fn,'sC');
    clear sC 
end
