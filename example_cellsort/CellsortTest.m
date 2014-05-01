%% Cellsort Artificial Data Test

% Eran Mukamel
% December 1, 2009
% eran@post.harvard.edu
    
fn = 'ArtificialData_SNR_0.1_FOV_250.tif';

%% 1. PCA

nPCs = 100;
flims = [];

[mixedsig, mixedfilters, CovEvals, covtrace, movm, movtm] = ...
    CellsortPCA(fn, flims, nPCs, [], [], []);

%% 2a. Choose PCs

[PCuse] = CellsortChoosePCs(fn, mixedfilters);
 
%% 2b. Plot PC spectrum

CellsortPlotPCspectrum(fn, CovEvals, PCuse)

%% 3a. ICA

nIC = length(PCuse);
mu = 0.5;

[ica_sig, ica_filters, ica_A, numiter] = CellsortICA(mixedsig, mixedfilters, CovEvals, PCuse, mu, nIC);

%% 3b. Plot ICs

tlims = [];
dt = 0.1;

figure(2)
CellsortICAplot('series', ica_filters, ica_sig, movm, tlims, dt, [], [], [1:20]);

%% 4a. Segment contiguous regions within ICs

smwidth = 2;
thresh = 2;
arealims = 10;
plotting = 1;

[ica_segments, segmentlabel, segcentroid] = CellsortSegmentation(ica_filters, smwidth, thresh, arealims, plotting);

%% 4b. CellsortApplyFilter 

subtractmean = 1;

cell_sig = CellsortApplyFilter(fn, ica_segments, flims, movm, subtractmean);

%% 5. CellsortFindspikes 

deconvtau = 0;
spike_thresh = 2;
normalization = 1;

[spmat, spt, spc] = CellsortFindspikes(ica_sig, spike_thresh, dt, deconvtau, normalization);

%% Show results

figure(2)
CellsortICAplot('series', ica_filters, ica_sig, movm, tlims, dt, 1, 2, [1:20], spt, spc);
