function [patchesChoice, pIdxChoice] = ...
    correspmrf(patches, pDst, pIdx, srcgridsize, refgridsize, varargin)
% function to be called for nnAggregator. 
% varargin are same as in patchmrf, excep[t that edgeDst defaults to correspdst if not specified
% recall that without specification, the patchOverlap defaults to mrf (mostly only important in
%   edgeDst)
%
% TODO - support somehow both patches and 
% TODO - maybe merge patchmrf with correspmrf? would need to include pIdx and refgridsize in
% patchmrf, but it would certainly make it more powerful!

    error('this is merged with patchmrf now');

    % check inputs
    % check for edgeDst
    if ~ismember('edgeDst', varargin)
        varargin = [varargin, 'edgeDst', @correspdst];
    end

    % get the displacement subscripts
    pSub = patchlib.corresp2disp(srcgridsize, refgridsize, permute(pIdx, [1, 3, 2]));

    % run an mrf using the displacement subscripts as "input patches". 
    % This is a bit of a trcik use of patchmrf.
    [~, bel, ~] = patchlib.patchmrf(cat(2, pSub{:}), srcgridsize, pDst, varargin{:});
    
    % use the posterior to choose the patches.
    [~, mi] = max(bel.nodeBel, [], 2);
    
    l = 1:numel(mi);
    pIdxChoice = pIdx(sub2ind(size(pIdx), l, mi(l)'));
    
    patchesChoice = zeros(size(patches, 1), size(patches, 2));
    for i = 1:numel(mi), 
        patchesChoice(i, :) = patches(i, :, mi(i)); 
    end
    
end


