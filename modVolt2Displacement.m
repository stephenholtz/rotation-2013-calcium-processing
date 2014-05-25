function stitchedVec = modVolt2Displacement(modBlock)

modBlock = modBlock - modBlock(1);

trans = find(abs(diff(modBlock)) > 4);
transMag = (diff(modBlock));

% Add the position vector to the previous
currInd = trans(1)+1;
stitchedVec = modBlock(1:trans(1));

for iT = trans(2:end)
    if transMag(iT) > 0
        direction = +1;
    else
        direction = -1;
    end

    currSegment = modBlock(currInd:iT);
    currOffset = currSegment(1)-stitchedVec(end);
    currSegment = currSegment-(direction*currOffset);
    stitchedVec = [stitchedVec currSegment]; %#ok
    currInd = iT+1;
end

currSegment = modBlock(currInd:end);
currOffset = currSegment(1)-stitchedVec(end);
currSegment = currSegment-(direction*currOffset);
stitchedVec = [stitchedVec currSegment];
