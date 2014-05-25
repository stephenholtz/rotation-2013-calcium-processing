function [xOut,yOut] = mask2roi(mask)
% verticies
% SLH
if ~islogical(mask)
    mask = ~~mask;
end

% Get a single ring around the mask with a silly filter
tracedROI = double(imfilter(mask,[-1 ; 1])|...
             imfilter(mask,[1 ; -1])|...
             imfilter(mask,[-1 , 1])|...
             imfilter(mask,[1 , -1]));
% transform the mask to fit normal coords for later plotting
tracedROI = tracedROI';

% find all of the ones from the filtered mask
[xIn,yIn] = find(tracedROI);

% use this traveling salesman function to get the right order
[xOut,yOut] = points2contour(xIn,yIn,1,'ccw');

