function [x,y,z] = mask2patch(mask)
% SLH

% Coordinates for plotting are different
inds = sort(find(mask));
[nR,nC] = size(mask);
[x,y] = ind2sub([nR,nC],inds);
z = ones(numel(x),1);

