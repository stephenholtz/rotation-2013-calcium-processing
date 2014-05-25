Repository for quick calcium imaging processing

 Sources:
 - Matlab Package, in Supplement of: Automated analysis of cellular signals from large-scale calcium imaging data. Eran A. Mukamel, Axel Nimmerjahn, Mark J. Schnitzer
 - Matlab scripts to process images using Mukamel Package
 
Batch workflow:
 - ImageJ registration (deintReg2ChanScanImage.ijm)
 - Crop / normalize / max proj frames (doInitProc.m)
 - Schnitzer-style processing (sortAllCells.m)
 - TODO: manual ROI processing (manualCellSort.m)
 - Pull in other useful fields for analysis (procExpData.m)
 - Plot data
