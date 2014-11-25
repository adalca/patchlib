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
