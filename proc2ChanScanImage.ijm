// Initial processing on ScanImage tiff stacks
//
// 1. Deinterlaces 2 Channels
// 2. Reigsters images with StackReg (manually set reference frame)
// 3. Saves registered stacks, prepended with chan_NUM_reg_ (where they were loaded from)
//
// SLH 2014

refSlice = 100;

origStackName = getTitle();
dataDir = getDirectory("image");
ch1FileName="chan_1_reg_"+origStackName;
ch2FileName="chan_2_reg_"+origStackName;

// Deinterleave the stack
run("Deinterleave", "how=2");

// Rename Deinterleave Defaults and Register with StackReg
selectWindow(origStackName+" #1")
rename(ch1FileName)
setSlice(refSlice);
run("StackReg", "transformation=[Rigid Body]");

selectWindow(origStackName+" #2")
rename(ch2FileName)
setSlice(refSlice);
run("StackReg", "transformation=[Rigid Body]");

// Save files in original dataDir
saveAs("tiff",dataDir+ch1FileName)
saveAs("tiff",dataDir+ch2FileName)
