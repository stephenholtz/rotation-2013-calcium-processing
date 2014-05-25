function sortedTrace = sortTraceByMax(traceBlock)

[~,indMax] = max(traceBlock,[],2);
[~,indSort] = sort(indMax);
sortedTrace = traceBlock(indSort,:);

