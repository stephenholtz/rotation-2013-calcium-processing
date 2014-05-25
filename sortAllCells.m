%% Use cell sorting code from Mukamel et al.,
% 
% SLH 2014

%% Set up the files for analysis
clear all; close all; clc;
addpath(genpath('~/grad_repos/calcium-processing'));

topDir = '~/local_data/sabatini/motor_cortex_useable';
folders = dir([topDir filesep '2014*']);

allFolders = 1:numel(folders);

for iFolder = 1 
    %fp = '/Users/stephenholtz/local_data/sabatini/20140430_02/';
    %sn = 'norm_crop_reg_ch1_cw_mctx_002001.tif';
    fp = fullfile(topDir,folders(iFolder).name);
    sn  = dir(fullfile(fp,'crop_reg_ch1*')); %#ok
    sn  = dir(fullfile(fp,'norm_crop_reg_ch1*'));
    sn = sn(1).name;

    fn= fullfile(fp,sn);
    fInfo = imfinfo(fn);
    disp(fInfo(1).Filename);

    %% 1. PCA
    nPCs = 100;
    flims = [];

    [mixedsig, mixedfilters, CovEvals, covtrace, movm, movtm] = CellsortPCA(fn, flims, nPCs, [], [], []);

    %% 2. Choose PCs
    [PCuse] = CellsortChoosePCs(fn, mixedfilters);
    CellsortPlotPCspectrum(fn, CovEvals, PCuse)

    %% 3 ICA
    nIC = length(PCuse);
    mu = 0.5;
    [ica_sig, ica_filters, ica_A, numiter] = CellsortICA(mixedsig, mixedfilters, CovEvals, PCuse, mu, nIC);

    tlims = [];
    dt = 0.1;
    figure(2)
    CellsortICAplot('series', ica_filters, ica_sig, movm, tlims, dt, [], [], PCuse);

    %% 4 Segment contiguous regions within ICs
    smwidth = 2;
    thresh = 2.5;
    arealims = 25;
    plotting = 1;

    [ica_segments, segmentlabel, segcentroid] = CellsortSegmentation(ica_filters, smwidth, thresh, arealims, plotting);

    subtractmean = 0; % was set to 1 by default
    cell_sig = CellsortApplyFilter(fn, ica_segments, flims, movm, subtractmean);

    %% 5. CellsortFindspikes 
    deconvtau = 0;
    spike_thresh = 2;
    normalization = 1;

    [spmat, spt, spc] = CellsortFindspikes(ica_sig, spike_thresh, dt, deconvtau, normalization);

    %% Save results
    sC.ica_sig = ica_sig;
    sC.ica_filters = ica_filters;
    sC.ica_A = ica_A;
    sC.cell_sig = cell_sig;
    sC.segcentroid = segcentroid;
    sC.ica_segments = ica_segments;
    sC.spmat = spmat;
    sC.spt = spt;
    sC.spc = spc;

    vn = 'sortedCells.mat';
    save(fullfile(fp,vn),'sC')

    %% Show results
    figure(3)
    CellsortICAplot('series', ica_filters, ica_sig, movm, tlims, dt, 1, 2, PCuse, spt, spc);
    
    %close all; figure;
end
