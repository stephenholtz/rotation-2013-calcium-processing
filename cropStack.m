function stackOutName = cropStack(stackLoc,overwriteFlag)
% crop the stack to get rid of pixel movement errors post registration
%
% SLH 2014

%% Load stack
%stackLoc = '/Users/stephenholtz/local_data/sabatini/20140430_02/reg_ch1_cw_mctx_002001.tif';

fInfo = imfinfo(stackLoc);
[stackLoc,stackName,ext] = fileparts(fInfo(1).Filename);
stackOutName = ['crop_' stackName ext];
disp(fullfile(stackLoc,stackOutName))

if exist(fullfile(stackLoc,stackOutName),'file') && ~overwriteFlag
    disp('File already processed')
    return
else
    stackIn = Tiff(fullfile(stackLoc,[stackName ext]),'r');

    %% Pull in stacks and find edges
        displayBWLabel = 0;

        width       = stackIn.getTag('ImageWidth');
        height      = stackIn.getTag('RowsPerStrip'); % == 'ImageLength' ?
        nSlices     = numel(fInfo);

        tempSlice  = zeros(height,width);
        edgeLabeledSlice = tempSlice;
        stackIn.setDirectory(1);

        for iSlice = 1:nSlices
            tempSlice = double(stackIn.read());
            edgeLabeledSlice = edgeLabeledSlice + bwlabel(tempSlice,4);

            if displayBWLabel
                divSlice = iSlice.*ones(height,width); %#ok
                subplot(2,1,1)
                imagesc(tempSlice)
                subplot(2,1,2)
                imagesc(floor((.8*divSlice).\edgeLabeledSlice))
                pause()
            end
            
            if iSlice < nSlices
                stackIn.nextDirectory
            end
        end

        % Make all edges from bwlabel apparent
        divSlice = nSlices.*ones(height,width);
        noiseCorrection = .96;
        flooredStack = floor(noiseCorrection*divSlice.\edgeLabeledSlice);
        % imagesc(flooredStack)
        
        % Find largest rectangle within this (using this function off of the file exchange)
        [~,~,~,M] = FindLargestRectangles(flooredStack,[1 1 0],[20 20]);
        % Slightly shrink this rectangle, to account for errors in rounding (noiseCorrection above)
        vertEdges = find(abs(diff(M(:,size(M,2)/2))))+1;
        horizEdges = find(abs(diff(M(size(M,1)/2,:))))+1;
        % Sometimes the size doesn't change
        if numel(vertEdges) < 2
            vertEdges = [1 size(M,2)];
        end
        if numel(horizEdges) < 2
            horizEdges = [1 size(M,1)];
        end
       
    %% Make stack output file
    stackOut    = Tiff(fullfile(stackLoc,stackOutName),'w');

    tagstruct.ImageWidth            = diff(horizEdges);
    tagstruct.RowsPerStrip          = diff(vertEdges);
    tagstruct.ImageLength           = diff(vertEdges);
    tagstruct.Photometric           = Tiff.Photometric.MinIsBlack;
    tagstruct.BitsPerSample         = stackIn.getTag('BitsPerSample');
    tagstruct.SamplesPerPixel       = stackIn.getTag('SamplesPerPixel');
    tagstruct.PlanarConfiguration   = Tiff.PlanarConfiguration.Chunky;
    tagstruct.Software              = ['MATLAB ' version];

    stackOut.setTag(tagstruct);

    %% Write the cropped image to disk
    stackIn.setDirectory(1);

    for iSlice = 1:nSlices
        tempSlice = (stackIn.read());
        stackOut.write((tempSlice([vertEdges(1)+1:vertEdges(2)],[horizEdges(1)+1:horizEdges(2)]))); %#ok
        if iSlice < nSlices
           stackIn.nextDirectory;
           stackOut.writeDirectory();
           stackOut.setTag(tagstruct);
        end
    end

    stackIn.close();
    stackOut.close();
end
