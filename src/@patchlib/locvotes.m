function [votes, pIdx, locIdx] = locvotes(loc, volSize, patches, grididx, patchSize)
% VOTEIDX votes given volume location
%   [votes, pIdx, locIdx] = locvotes(loc, volSize, patches, grididx, patchSize) patch votes for a
%   given volume location loc inside a volume of size volSize, patches are the resulting patches
%   from a knnsearch sized (N x P x K), grididx is the patches grid. patchSize is the patch size.
%
%   Note: numel(grididx) == N, prod(patchSize) = P.
%
%   Author: adalca@csail.mit.edu   
    
    [pIdx, locIdx] = voteidx(loc, volSize, grididx, patchSize);
    assert(isempty(pIdx) || max(pIdx) <= size(patches, 1));
    
    if ~isempty(pIdx)
        [pIdxSub, locIdxSub, Ksub] = ndgrid(pIdx, locIdx, 1:size(patches, 3));
        idx = sub2ind(size(patches), pIdxSub(:), locIdxSub(:), Ksub(:));
        votes = patches(idx);
    else
        votes = [];
    end

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
