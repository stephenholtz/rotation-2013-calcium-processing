function traceBlockNorm = normTrace2Max(traceBlock)
traceBlockNorm = traceBlock./(max(traceBlock,[],2)*ones(1,size(traceBlock,2)));
