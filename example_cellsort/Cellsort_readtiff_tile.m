function [mixedsig, mixedfilters, CovEvals, covtrace, movm, movtm] = ...
    Cellsort_readtiff_tile(fn, flims, nPCs, outputdir, badframes)
%
%
% Eran Mukamel, eran@post.harvard.edu, 2010

tic

%%

%-----------------------
% Check inputs
if isempty(dir(fn))
    error('Invalid input file name.')
end
if (nargin<2)||(isempty(flims))
    nt_full = tiff_frames(fn);
    flims = [1,nt_full];
end

useframes = setdiff((flims(1):flims(2)), badframes);
nt = length(useframes);

if nargin<3 || isempty(nPCs)
    nPCs = min(150, nt);
end
if nargin<4 || isempty(outputdir)
    outputdir = [pwd,'/cellsort_preprocessed_data/'];
end
if nargin<5
    badframes = [];
end
if isempty(dir(outputdir))
    mkdir(pwd, '/cellsort_preprocessed_data/')
end
if outputdir(end)~='/';
    outputdir = [outputdir, '/'];
end

%-----------

tiledir = [fn,'_tiles/'];
flist = dir([tiledir,'jtile*']);

if isempty(dir([tiledir,'jtile0_ktile1_.tif']))
    oldnamescheme = 0;
    fprintf('Using new naming scheme.\n')
else
    oldnamescheme = 1;
    fprintf('Using old naming scheme.\n')
end

if (nargin<2)||(isempty(flims))
    nt = tiff_frames([tiledir,flist(1).name]);
    flims = [1,nt];
else
    nt = diff(flims) + 1;
end
if nargin<5
    badframes = [];
end
useframes = setdiff([flims(1):flims(2)], badframes);

[fpath, fname, fext] = fileparts(fn);
if isempty(fpath)
    fpath = '.';
end
if isempty(badframes)
    fnmat = [outputdir, fname, '_',num2str(flims(1)),',',num2str(flims(2)), '_', date,'.mat'];
else
    fnmat = [outputdir, fname, '_',num2str(flims(1)),',',num2str(flims(2)),'_selframes_', date,'.mat'];
end
if ~isempty(dir(fnmat))
    fprintf('Movie already processed.\n')
    load(fnmat)
    return
end

ntiles = length(flist);
[pixw,pixh] = size(imread(fn,1));
npix = pixw*pixh;
c1 = zeros(nt);
movtm = zeros(1,nt);
fprintf('Finished allocating variables; ')
toc
for i=1:ntiles
    tilefn = [tiledir,flist(i).name];
    jtile = str2num( flist(i).name(findstr(flist(i).name, 'jtile')+5));
    ktile = str2num( flist(i).name(findstr(flist(i).name, 'ktile')+5));
    
    [tilew,tileh] = size(imread(tilefn,1));
    npixtile = tilew*tileh;
    
    movcurr = zeros(tilew, tileh, nt);
    for jj=useframes
        % Read in the tiles. Note that tiles have already been
        % normalized (DF/F).
        movcurr(:,:,jj-flims(1)+1) = imread(tilefn,jj);
    end
    
    % Correct for pixels that are zero due to image motion correction
    movcurr(movcurr==0) = 1;
    
    movcurr = reshape(movcurr, npixtile, nt) - 1; % Remove mean
    c1 = c1 + (movcurr'*movcurr)/npix;
    movtm = movtm + mean(movcurr,1)/ntiles;
    fprintf('Processed tile number %3.0f of %3.0f; ', i, ntiles)
    toc
end
covmat = c1 - movtm'*movtm;
covtrace = trace(covmat);
clear c1 movcurr
fprintf('Finished reading mixed signals; ')
toc

opts.disp = 0;
opts.issym = 'true';
if nPCs<size(covmat,1)
    [mixedsig, CovEvals] = eigs(covmat, nPCs, 'LM', opts);
    CovEvals = diag(CovEvals);
else
    [mixedsig, CovEvals] = eig(covmat);
    [CovEvals,Dindex] =  sort(diag(CovEvals), 'descend');
    mixedsig = mixedsig(:,Dindex);
    nPCs = size(CovEvals,1);
end
if nnz(CovEvals<=0)
    nPCs = nPCs - nnz(CovEvals<=0);
    fprintf(['Throwing out ',num2str(nnz(CovEvals<0)),' negative eigenvalues; new # of PCs = ',num2str(nPCs),'. \n']);
    mixedsig = mixedsig(:,CovEvals>0);
    CovEvals = CovEvals(CovEvals>0);
end

percentvar = 100*sum(CovEvals)/covtrace;
fprintf(['Computed PCA; first ',num2str(nPCs),' PCs contain ',num2str(percentvar,3),' percent of the variance.\n'])
clear covmat

Sinv = inv(diag(CovEvals.^(1/2)));
fprintf('Finished computing PCs; ')
toc

nt = diff(flims) + 1;

mixedfilters = zeros(pixw,pixh,nPCs);
jtile = []; ktile = [];
tilex = 0; tiley = 0;
for i=1:ntiles
    tilefn = [flist(i).name];
    fnbars = findstr(tilefn, '_');
    jtile = str2num( tilefn((findstr(tilefn, 'jtile')+5):(fnbars(1)-1)));
    ktile = str2num( tilefn((findstr(tilefn, 'ktile')+5):(fnbars(2)-1)));
    tilefn = [tiledir,flist(i).name];
    
    [tilew,tileh] = size(imread(tilefn,1));
    npixtile = tilew*tileh;
    
    movcurr = zeros(tilew, tileh, nt);
    for j=1:nt
        movcurr(:,:,j) = imread(tilefn,j + flims(1) - 1);
    end
    
    %%%%%%%%%%%%%%%%
    movcurr = movcurr - 1; %%%% Remove mean
    %%%%%%%%%%%%%%%%
    
    movcurr = reshape(movcurr, npixtile, nt);
    
    % Correct for pixels that are zero due to image motion correction
    movcurr(movcurr==0) = 1;
    
    % Add back in the mean of each time frame (?? Should subtract?)
    movcurr = movcurr - ones(npixtile,1) * movtm;
    
    if oldnamescheme==1
        mixedfilters(ktile*tilew+1:(ktile+1)*tilew, jtile*tileh+1:(jtile+1)*tileh,:) = reshape(movcurr * mixedsig * Sinv, tilew,tileh,nPCs);
    else
        mixedfilters(ktile+[1:tilew], jtile+[1:tileh], :) = reshape(movcurr * mixedsig * Sinv, tilew,tileh,nPCs);
    end
    
    fprintf('Processed tile number %3.0f of %3.0f; ', i, ntiles)
    toc
end
clear movcurr

mixedfilters = reshape(mixedfilters, npix, nPCs);
mixedsig = mixedsig';
fprintf('Finished reading mixing vectors; ')
toc

f0fn = [tiledir, 'F0.tif'];
movm = imread(f0fn);

save(fnmat,'mixedfilters','CovEvals','mixedsig', ...
    'movm','movtm','covtrace')
fprintf('Saved data; ')
toc



function j = tiff_frames(fn)
%
% n = tiff_frames(filename)
%
% Returns the number of slices in a TIFF stack.
%
%

status = 1; j=0;
jstep = 10^3;
while status
    try
        j=j+jstep;
        imread(fn,j);
    catch
        if jstep>1
            j=j-jstep;
            jstep = jstep/10;
        else
            j=j-1;
            status = 0;
        end
    end
end
