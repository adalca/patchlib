function [votes, pIdx, locIdx, idx, Ksub] = locvotes(loc, patches, grididx, patchSize, volSize)
% VOTEIDX votes given volume location
%   votes = locvotes(loc, patches, grididx, patchSize, volSize) patch votes for a given volume
%   location loc inside a volume of size volSize, patches are the resulting patches from a knnsearch
%   sized (N x P x K), grididx is the patches grid. patchSize is the patch size.
%
%   votes = locvotes(loc, patches, gridloc, patchSize) % allows for passing the gridloc directly.
%
%   [votes, pIdx, locIdx, idx] = locvotes(...) also allows for
%   the return of pIdx (the index of which patches are returned, i.e. index in rows of 'patches'),
%   and locIdx is the index of the locations used for those patches. Note that all K votes are
%   returned for each of these. idx is the final index computed from pIdx and locIdx and considering
%   all K entries --- that is, votes = patches(idx);
%
%   Warning: do not use this to look over many voxels, it is slow for that purpose! If you need to
%   do that, do a vol2lib call of an index volume (i.e. reshape(1:prod(volSize), volSize)). see
%   rowquilt().
%
%   Note: numel(grididx) == N, prod(patchSize) = P.
%
%   Author: adalca@csail.mit.edu   
    
    % input checking
    narginchk(4, 5);
    if nargin == 5
        grididx = grididx(:);
        assert(numel(grididx) == size(patches, 1), 'grididx and patches are not compatible');
        gridloc = ind2subvec(volSize, grididx);
    else
        gridloc = grididx;
        assert(size(gridloc, 1) == size(patches, 1), 'gridloc and patches are not compatible');
    end
    assert(prod(patchSize) == size(patches, 2), 'patchSize and patches are not compatible');

    % retreive vote indexes
    [pIdx, locIdx] = voteidx(loc, gridloc, patchSize);
    assert(isempty(pIdx) || max(pIdx) <= size(patches, 1), ...
        'pIdx failure: %d, %d', max(pIdx), size(patches, 1));
    
    % obtain indexes into the patches variable
    if ~isempty(pIdx)
        [pIdxSub, Ksub] = ndgrid(pIdx, 1:size(patches, 3));
        [locIdxSub, Ksub2] = ndgrid(locIdx, 1:size(patches, 3));
        assert(all(Ksub(:) == Ksub2(:)));
        idx = sub2ind(size(patches), pIdxSub(:), locIdxSub(:), Ksub(:));
    else
        idx = [];
        Ksub = [];
    end
    
    assert(numel(idx) == numel(pIdx) * size(patches, 3));
    votes = patches(idx);
end

function [pIdx, locIdx] = voteidx(loc, gridloc, patchSize)
% VOTEIDX get the voting patches and the location inside those patches for a given volume location
%   [pIdx, locIdx] = voteidx(loc, gridloc, patchSize) get the voting patches and the location inside
%   those patches for a given volume location. loc - the location inside a volume of size volSize.
%   gridloc is the locations of the patches grid. patchSize is the patch size.
%
%   Author: adalca@csail.mit.edu
    
    assert(numel(loc) == numel(patchSize));
    
    sel = bsxfun(@ge, gridloc, (loc - patchSize + 1));
    sel = sel & bsxfun(@le, gridloc, loc);
    sel = all(sel, 2);
    
    pIdx = find(sel);
    pSel = gridloc(sel, :);
    
    locIdx = subvec2ind(patchSize, bsxfun(@minus, loc, pSel - 1));
end    
