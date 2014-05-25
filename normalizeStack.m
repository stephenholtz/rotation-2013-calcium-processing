function stackOutName = normalizeStack(stackLoc,overwriteFlag)
%% Normalize the stack - images should be cropped to exclude registration
% errors prior to this step
%
% SLH 2014

%% Load in files
%stackLoc = '/Users/stephenholtz/local_data/sabatini/20140430_02/crop_reg_ch1_cw_mctx_002001.tif';
fInfo = imfinfo(stackLoc);
[stackLoc,stackName,ext] = fileparts(fInfo(1).Filename);
stackOutName = ['norm_' stackName ext];
disp(fullfile(stackLoc,stackOutName))

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
    normStack   = zeros(height,width,nSlices);
    stackIn.setDirectory(1);

    for iSlice = 1:nSlices
        normStack(:,:,iSlice) = double(stackIn.read());
        if iSlice < nSlices
            stackIn.nextDirectory
        end
    end

    % divide by each pixel's mean and subtract 1
    meanSlice = mean(normStack,3);
    for iSlice = 1:nSlices
        normStack(:,:,iSlice) = (normStack(:,:,iSlice)./meanSlice) - 1;
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
    for iSlice = 1:nSlices
        stackOut.write(uint16(normStack(:,:,iSlice)));
        if iSlice < nSlices
           stackOut.writeDirectory();
           stackOut.setTag(tagstruct);
        end
    end

    % Save normalized stack as a mat file
    % save(fullfile(stackLoc,stackOutName),'normStack');
    stackIn.close();
    stackOut.close();
end
