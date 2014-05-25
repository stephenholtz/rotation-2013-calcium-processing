function stackOutName = makeMaxProj(stackLoc,overwriteFlag)
%% maxproj the stack
%
% SLH 2014

%% Load in files
fInfo = imfinfo(stackLoc);
[stackLoc,stackName,ext] = fileparts(fInfo(1).Filename);
stackOutName = ['maxProj_' stackName ext];
disp(fullfile(stackLoc,stackOutName))
if ~exist('overwriteFlag','var');
    overwriteFlag = 0;
end

if exist(fullfile(stackLoc,stackOutName),'file') && ~overwriteFlag
    disp('File already processed')
    return
else
    stackIn     = Tiff(fullfile(stackLoc,[stackName ext]),'r');
    width       = stackIn.getTag('ImageWidth');
    height      = stackIn.getTag('RowsPerStrip'); % == 'ImageLength' ?
    nSlices     = numel(fInfo);

    %% Processing

    % Normalize
    maxStack   = zeros(height,width);
    stackIn.setDirectory(1);

    for iSlice = 1:nSlices
        tempSlice = double(stackIn.read());
        replaceMat=find(maxStack<tempSlice);
        maxStack(replaceMat) = tempSlice(replaceMat);
        if iSlice < nSlices
            stackIn.nextDirectory
        end
    end

    %% Save as tiff
    stackOut    = Tiff(fullfile(stackLoc,stackOutName),'w');

    tagstruct.ImageWidth            = width;
    tagstruct.RowsPerStrip          = height;
    tagstruct.ImageLength           = height;
    tagstruct.Photometric           = Tiff.Photometric.MinIsBlack;
    tagstruct.BitsPerSample         = stackIn.getTag('BitsPerSample');
    tagstruct.SamplesPerPixel       = stackIn.getTag('SamplesPerPixel');
    tagstruct.PlanarConfiguration   = Tiff.PlanarConfiguration.Chunky;
    tagstruct.Software              = ['MATLAB ' version];

    stackOut.setTag(tagstruct);

    %% Write the cropped image to disk
    disp('writing tiff stack out')
    stackOut.write(uint16(maxStack));
    stackOut.writeDirectory();
    stackOut.setTag(tagstruct);

    stackIn.close();
    stackOut.close();
end
