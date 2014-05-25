%% Plot activity profiles from sorted cells:
%
% SLH 2014

%% Figs to make
% 0 - colored ROI
makeROIimages = 1;
% 1 - falsecolored deltaF/F movie 
% 2 - line plot DelataF/F for all profiles w/ motor 
makeLineActivityMultiPlot = 1;
% 3 - heatmap plot DeltaF/F for all profiles w/ motor 
makeTraceHeatmapMultiPlot = 1;
% 4 - mean DeltaF/F pre, during, and after motor
% 5 - XC of activity w/motor vs profile DeltaF/F
% 6 - Dendrites vs cell bodies in plots

% Get rid of pesky warnings
%#ok<*UNRCH>
%#ok<*NGRW>

%% Load Files
addpath(genpath('~/personal_repos/matlab-utils'));
addpath(genpath('~/grad_repos/calcium-processing'));

topDir = '~/local_data/sabatini/motor_cortex_useable';
folders = dir([topDir filesep '2014*']);
%foldToProc = 1:numel(folders);

folderNum = 10;
fp = fullfile(topDir,folders(folderNum).name);
disp(fp);

% load sC struct with all exp / roi data
vn = 'sortedCells.mat';
fn = fullfile(fp,vn);
load(fn);

% load in max proj image
stackName = dir(fullfile(fp,'maxProj_crop_*'));
stackName = stackName(1).name;
stackIn = Tiff(fullfile(fp,stackName),'r');
maxProjImg = double(stackIn.read());
stackIn.close();

%% Figure Vars 
imgColor = [1 1 1];
lgFont = 16;
roiColor = [0 .2 1];
lnWidth = 1;
colorA = [1 .2 0];
CM = hot;

%% 0 ROI / Images 
if makeROIimages
    % maximum projection
    figure('color',imgColor);
    imagesc(maxProjImg);
    title(stackName,'FontSize',lgFont,'interpreter','none')
    colormap(CM); axis off; hold on

    % show all manual ROIs
    figure('color',imgColor);
    imagesc(maxProjImg);
    title(stackName,'FontSize',lgFont,'interpreter','none')
    colormap(CM); axis off; hold on
    for iSeg = 1:numel(sC.manROI)
        mask = sC.manROI(iSeg).mask;
        if sum(mask(:)) > 1
            [x,y] = mask2roi(mask);
            roiH = plot(x,y);
            set(roiH,'Color',roiColor,'LineWidth',lnWidth);
        end
    end

    % show all automatic ROIs
    figure('color',imgColor);
    imagesc(maxProjImg);
    title(stackName,'FontSize',lgFont,'interpreter','none')
    colormap(CM); axis off; hold on

    for iSeg = 1:size(sC.ica_segments,1)
        mask = squeeze(sC.ica_segments(iSeg,:,:));
        if sum(mask(:)) > 2
            [x,y] = mask2roi(mask);
            roiH = plot(x,y);
            set(roiH,'Color',roiColor,'LineWidth',lnWidth);
        end
    end

end
%% 1 - Make Falsecolor deltaF/F movie

%% 2 - line plot DelataF/F for all profiles w/ motor 
% plot all of the profiles with normalized (to max) on diff rows
if makeLineActivityMultiPlot

    figure('color',imgColor);
    title(stackName,'FontSize',lgFont,'interpreter','none')
    colormap(CM); axis off; hold on

    nSegs = 10;

    % Subplot vars
    nWide       = 1;    nHigh       = nSegs+1;
    widthGap    = 0.05; heightGap   = 0;
    widthOffset = 0.05; heightOffset= 0;
    sp_positions = getFullPageSubplotPositions(nWide,nHigh,widthGap,heightGap,widthOffset,heightOffset);

    for iSeg = 1:nSegs
        subplot('Position',sp_positions{iSeg,1})
        %currTrace = sC.ica_mandFoFroi(:,iSeg);
        currTrace = sC.cell_sig(iSeg,:);
        currTrace = currTrace./max(currTrace);
        timeTrace = round((1:numel(currTrace)).*sC.frameDur/1000);
        plot(timeTrace,currTrace);
        box off; axis off
        if iSeg == nSegs
            axis on
        end
    end

    ylabel({'Norm.','\DeltaF/F'},'FontSize',lgFont)
    xlabel('Time (s)','FontSize',lgFont)

end

%% 3 - heatmap plot DeltaF/F for all profiles w/ motor (normalized)
if makeTraceHeatmapMultiPlot

    figure('color',imgColor);
    title(stackName,'FontSize',lgFont,'interpreter','none')

    % Subplot vars
    nWide       = 1;    nHigh       = 5;
    widthGap    = 0.05; heightGap   = 0.03;
    widthOffset = 0.05; heightOffset= 0.02;
    sp_positions = getFullPageSubplotPositions(nWide,nHigh,widthGap,heightGap,widthOffset,heightOffset);

    % get mildly processed calcium traces
    %traceBlock = sC.cell_sig;
    traceBlock = sC.ica_mandFoFroi'; 
    traceBlockNorm = normTrace2Max(traceBlock); 
    traceBlockSort = sortTraceByMax(traceBlockNorm);

    % get only the daq data from where there were frames taken
    motorFrameLog = find((sC.frameInd > 0) & (sC.frameInd < size(sC.cell_sig,2)));
    motorFrameLog = [motorFrameLog motorFrameLog(end)+1:motorFrameLog(end)+sC.frameDur];
   motorBlock = sC.AD.ch0.data(motorFrameLog);

    % Unwind the mod signal off of the wheel
    if range(motorBlock) > 4.5
        stitchedVec = modVolt2Displacement(motorBlock);
    else
        stitchedVec = motorBlock - motorBlock(1);
    end

    subplot('Position',sp_positions{1})
    imagesc(traceBlock);
    axis off;
    box off;
    title('GCaMP6s + Motor activity','FontSize',lgFont);
    ylabel('Ca^2^+ Profile','FontSize',lgFont)
    set(gca,'XtickLabel',{''})
    subplot('Position',sp_positions{2})
    imagesc(traceBlockNorm);
    axis off;
    box off;
    subplot('Position',sp_positions{3})
    imagesc(traceBlockSort);
    ylabel('Ca^2^+ Profile','FontSize',lgFont)
    box off;
    set(gca,'Xtick',1:100:size(traceBlock,2),'XtickLabel',(timeTrace(1:101:end)))
    xlabel('Time (s)','FontSize',lgFont)
subplot('Position',sp_positions{4})
    plot(motorBlock,'Color','k','LineWidth',2);
    set(gca,'XtickLabel',{''})
    axis off;
    box off;
    subplot('Position',sp_positions{5})
    plot(stitchedVec,'Color','k','LineWidth',2);
    ylabel('Wheel Position (V)','FontSize',lgFont)
    box off;

    colormap(CM);
    
end

%% 4 - mean DeltaF/F pre, during, and after motor

figure('color',imgColor);
[bButt,aButt] = butter(1,0.02,'low');
filtStitchedVec = filtfilt(bButt,aButt,stitchedVec);
plot(stitchedVec)
hold all;
plot(motorBlock,'Color','k')
plot(filtStitchedVec,'LineWidth',4,'Color',colorA)
box off;
title('Mod to Position','FontSize',lgFont+3)
xlabel('DAQ Card Samples','FontSize',lgFont+3)
ylabel('Voltage-Position Signal','FontSize',lgFont+3)

didMove = [0 abs(diff(filtStitchedVec)) > 0.0002];
durImgFrameInds = sC.frameInd(motorFrameLog);
motorFrames = unique(durImgFrameInds(~~didMove));
nonMotorFrames = unique(durImgFrameInds(~didMove));

motorActivity = zeros(1,size(traceBlock,1));
nonMotorActivity = zeros(1,size(traceBlock,1));
for iSig = 1:size(traceBlock,1)
    motorActivity(:,iSig) = mean(traceBlockNorm(iSig,motorFrames));
    nonMotorActivity(:,iSig) = mean(traceBlockNorm(iSig,nonMotorFrames));
end

figure('color',imgColor);
subplot(1,2,1)
boxplot([nonMotorActivity',motorActivity'],'PlotStyle','compact')
ylabel({'Mean Profile','Fluorescence (AU)'},'FontSize',lgFont)
set(gca,'Xtick',[1 2],'XtickLabel',{'Non Motor','Motor'})
box off;
axis([.5 2.5 0 .8])
subplot(1,2,2)
plot([nonMotorActivity;motorActivity],'Color',colorA)
hold all
meanMotorChange = mean([nonMotorActivity;motorActivity],2);
plot(meanMotorChange,'k','linewidth',6)
box off;
axis([.5 2.5 0 .8])
%ylabel({'Mean Profile','Fluorescence (AU)'},'FontSize',lgFont)
set(gca,'Xtick',[1 2],'XtickLabel',{'Non Motor','Motor'})

%% 5 - XC of activity w/motor vs profile DeltaF/F
[bButt,aButt] = butter(1,0.4,'low');
filtTraceBlock = filtfilt(bButt,aButt,traceBlockNorm')';
figure('color',imgColor);
plot(filtTraceBlock','Color',colorA)
hold all;
plot(filtStitchedVec,'k')

% index into the trace block with the frame inds to expand 
% the deltaF/F to be the same size as filtered motor activity 
% for the cross correlations
expdTraceBlock = zeros(size(traceBlock,1),numel(durImgFrameInds));
for iSig = 1:size(traceBlock,1)
    expdTraceBlock(iSig,:) = filtTraceBlock(iSig,durImgFrameInds);
end
%plot(expdTraceBlock');

% do the XC (heavily filter the animal's velocity and normalize)
[bButt,aButt] = butter(1,0.0002,'low');
velMotorSig = [0 abs(diff(filtStitchedVec))];
filtVelMotorSig = filtfilt(bButt,aButt,velMotorSig);
filtVelMotorSig = filtVelMotorSig/mean(filtVelMotorSig);
filtVelMotorSig = filtVelMotorSig/max(filtVelMotorSig);
normMotorBlock = motorBlock-median(motorBlock(1:10));
normMotorBlock = normMotorBlock/max(normMotorBlock);
figure('color',imgColor);
plot(normMotorBlock,'Color','k')
hold all;
plot(filtVelMotorSig,'LineWidth',4,'Color',colorA)
box off;
title('Velocity','FontSize',lgFont+3)
xlabel('DAQ Card Samples','FontSize',lgFont+3)
ylabel('Normalized Voltage-Position Signal','FontSize',lgFont+3)



traceMotorCorr = zeros(size(traceBlock,1),1);
for iSig = 1:size(traceBlock,1)
    currCorr = corrcoef(expdTraceBlock(iSig,:),filtVelMotorSig);
    traceMotorCorr(iSig) = currCorr(2,1);
end
figure('color',imgColor);
[f,xi]=(ksdensity(traceMotorCorr,'bandwidth',.025));
plot(xi,f,'Color','k')
box off;
hold on;
plot([0 0],get(gca,'YLim'),'r--');
title('Velocity Correlation Coeficients','FontSize',lgFont);
ylabel('Probability Density','FontSize',lgFont);
xlabel('\DeltaF/F_0 vs Velocity Correlation Coef.','FontSize',lgFont)

figure('color',imgColor);
scatter(traceMotorCorr,trapz(traceBlock,2));
box off;
title('"Activity" vs Motor Correlation','FontSize',lgFont);
ylabel('\Sigma Raw Fluorescence (AU)','FontSize',lgFont)
xlabel('\DeltaF/F_0 vs Velocity Correlation Coef.','FontSize',lgFont)

%% 6 - Dendrites vs cell bodies in plots

