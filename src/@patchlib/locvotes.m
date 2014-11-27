function [votes, pIdx, locIdx, idx] = locvotes(loc, volSize, patches, grididx, patchSize)
% VOTEIDX votes given volume location
%   votes = locvotes(loc, volSize, patches, grididx, patchSize) patch votes for a given volume
%   location loc inside a volume of size volSize, patches are the resulting patches from a knnsearch
%   sized (N x P x K), grididx is the patches grid. patchSize is the patch size.
%
%   [votes, pIdx, locIdx, idx] = locvotes(loc, volSize, patches, grididx, patchSize) also allows for
%   the return of pIdx (the index of which patches are returned, i.e. index in rows of 'patches'),
%   and locIdx is the index of the locations used for those patches. Note that all K votes are
%   returned for each of these. idx is the final index computed from pIdx and locIdx and considering
%   all K entries --- that is, votes = patches(idx);
%
%   Note: numel(grididx) == N, prod(patchSize) = P.
%
%   Author: adalca@csail.mit.edu   
    
    % input checking
    narginchk(5, 5);
    grididx = grididx(:);
    assert(numel(grididx) == size(patches, 1), 'grididx and patches are not compatible');
    assert(prod(patchSize) == size(patches, 2), 'patchSize and patches are not compatible');

    % retreive vote indexes
    [pIdx, locIdx] = voteidx(loc, volSize, grididx, patchSize);
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
    end
    
    assert(numel(idx) == numel(pIdx) * size(patches, 3));
    votes = patches(idx);
end

function [pIdx, locIdx] = voteidx(loc, volSize, grididx, patchSize)
% VOTEIDX get the voting patches and the location inside those patches for a given volume location
%   [pIdx, locIdx] = voteidx(loc, volSize, grididx, patchSize) get the voting patches and the
%   location inside those patches for a given volume location. loc - the location inside
%   a volume of size volSize. grididx is the patches grid. patchSize is the patch size.
%
%   Author: adalca@csail.mit.edu
    
    assert(numel(loc) == numel(patchSize));
    
    gridloc = ind2subvec(volSize, grididx);
    
    sel = bsxfun(@ge, gridloc, (loc - patchSize + 1));
    sel = sel & bsxfun(@le, gridloc, loc);
    sel = all(sel, 2);
    
    pIdx = find(sel);
    pSel = gridloc(sel, :);
    
    locIdx = subvec2ind(patchSize, bsxfun(@minus, loc, pSel - 1));
end    
