function [pIdx, pRefIdxs, pDst] = volknnglobalsearch(src, refs, varargin)
% volknnglobalsearch. private function for volknnsearch.
%
% [pIdx, pRefIdxs, pDst] = volknnglobalsearch(src, refs, knnarg1, ...)
%
%   src is a struct with fields
%       mask
%       grididx
%       lib
%   refs is a struct with fiels
%       lib (cell)
%       refidx (cell)

    % compute one ref library, and associated indexes
    refslib = cat(1, refs.lib);
    refsidx = cat(1, refs.refidx);
       
    % do knn search for elements in mask.
    mask = src.mask;
    gidx = src.grididx;
    mask = mask(gidx);
    lib = src.lib;
    [pIdxm, pDstm] = knnsearch(refslib, lib(mask, :), varargin{:});
    pRefIdxsm = refsidx(pIdxm);
    pRefIdxsm = reshape(pRefIdxsm, size(pIdxm)); % necessary if size(pIdxm, 1) == 1;
    
    % repopulate structures
    if any(~mask(:))
        pIdx = maskvox2vol(pIdxm, mask(:), @nan);
        pDst = maskvox2vol(pDstm, mask(:), @nan);
        pRefIdxs = maskvox2vol(pRefIdxsm, mask(:), @nan);
    else
        pIdx = pIdxm;
        pDst = pDstm;
        pRefIdxs = pRefIdxsm;
    end
    
    % fix pIdx for return
    sizes = cellfun(@(x) size(x, 1), {refs.lib});
    for i = 1:numel(refs)
        pIdx(pRefIdxs == i) = pIdx(pRefIdxs == i) - sum(sizes(1:i-1));
    end
end
