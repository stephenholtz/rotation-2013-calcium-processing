function [m,n] = mask2coords(mask)
% takes in a mask and returns the r,c coordinates for the roi
% for viewing
%
% SLH

% Coordinates for plotting are different
inds = sort(find(mask));
[nR,nC] = size(mask);
[m,n] = ind2sub([nR,nC],inds);
