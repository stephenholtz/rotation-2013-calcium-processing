% test Dfof calcs from automatic cell sorting vs hand sorting

%% Load in experimental data etc.,
topDir = '~/local_data/sabatini/motor_cortex_useable';
folders = dir([topDir filesep '2014*']);
iFolder = 1;

fp = fullfile(topDir,folders(iFolder).name);
sn = dir(fullfile(fp,'crop_reg_ch1*'));
sn = sn(1).name;

fn = fullfile(fp,sn);
fInfo = imfinfo(fn);
disp(fInfo(1).Filename);

%% Load  summary processed exp data
vn = 'sortedCells.mat';
load(fullfile(fp,vn));

% load in max proj image
stackName = dir(fullfile(fp,'maxProj_crop_*'));
stackName = stackName(1).name;
stackIn = Tiff(fullfile(fp,stackName),'r');
maxProjImg = double(stackIn.read());
stackIn.close();

% load in the tiff stack if it isn't done
if exist('rawFStack','var')
    disp('stack exists in memory')
else
    stackIn     = Tiff(fn,'r');
    width       = stackIn.getTag('ImageWidth');
    height      = stackIn.getTag('RowsPerStrip'); % == 'ImageLength' ?
    nSlices     = numel(fInfo);

    % Import stack
    rawFStack = zeros(height,width,nSlices);
    dFoFStack = rawFStack;
    stackIn.setDirectory(1);
    for iSlice = 1:nSlices
        rawFStack(:,:,iSlice) = double(stackIn.read());
        if iSlice < nSlices
            stackIn.nextDirectory
        end
    end
    stackIn.close();

    % make a DfoF stack the svoboda way (F0 = mode of pixel on whole stack)
    modeStack = mode(rawFStack,3);
    for iSlice = 1:nSlices
        dFoFStack(:,:,iSlice) = 100*((rawFStack(:,:,iSlice)./modeStack)-1);
    end
end

%% Find the timeseries dfof based on ica_segments
nSegs = size(sC.ica_segments,1);
dFoFroi = zeros(nSlices,nSegs);

for iSeg = 1:nSegs
    roiInds = find(squeeze(sC.ica_segments(iSeg,:,:)));
    for iSlice = 1:nSlices
        tmpStack = dFoFStack(:,:,iSlice);
        dFoFroi(iSlice,iSeg) = mean(tmpStack(roiInds));
    end
end
% add to the sC struct
sC.ica_dFoFroi = dFoFroi; 

%% Find the timeseries of dfof based on hand drawn rois (displaying both the max projection and the ica_segments)
nFilts = size(sC.ica_filters,1);
currFilts = [];
ignoreFiltInds = [];
segIter = 0;

figure(1);
imagesc(maxProjImg);

for iFilt = 1:nFilts 
    currFiltImg = squeeze(sC.ica_filters(iFilt,:,:));
    figure(2);
    imagesc(currFiltImg);

    disp(['Select ROIs Based on ica_filters ' num2str(iFilt) ' of ' num2str(nFilts)]);
    doMore = input('Select ROI [1/0] ?  ');
    while ~~doMore
        fh_h = imfreehand(gca);
        manual(segIter+1).mask  = fh_h.createMask; %#ok
        
        % error check for single point clicks
        if sum(manual(segIter+1).mask(:)) < 3
            disp('oops try again')
            fh_h = imfreehand(gca);
            manual(segIter+1).mask  = fh_h.createMask; %#ok
        end
        
        % update max proj with drawn masks
        [tx,ty] = mask2roi(fh_h.createMask);
        figure(1); 
        hold all;
        plot(tx,ty,'r');
        figure(2);

        segIter = segIter + 1;
        doMore = input('Select another [1/0] ?  ');
    end
end

disp('Calculating ROI dfofs')
mandFoFroi = zeros(nSlices,nSegs);
for iSeg = 1:(segIter-1)
    roiInds = find(manual(iSeg).mask);
    for iSlice = 1:nSlices
        tmpStack = dFoFStack(:,:,iSlice);
        mandFoFroi(iSlice,iSeg) = mean(tmpStack(roiInds));
    end
end

% add to the sC struct
sC.ica_mandFoFroi = mandFoFroi; 
sC.manROI = manual;

%% Save sC
%save(fullfile(fp,vn),'sC');
