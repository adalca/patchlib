function reshapedPatches = reshapeto2D(patches, patchSize)
% reshapeto2D reshape ND patches to tiled 2D slices
%
%   reshapedPatches = reshapeto2D(alreadyShapedPatch)
%
%   reshapedPatches = reshapeto2D(patches, patchSize) assumes patches as in N*(prod(patchSize)) shape
%
% contact: adalca @ csail

    if nargin == 1
        patchSize = size(patches);
        reshapedPatches = reshape(patches(:), [patchSize(1), prod(patchSize(2:end))]);

    else
        % split into a cell of patches
        patchescell = dimsplit(1, patches);

        % reshape each patch
        pfn = @(p) patchview.reshapeto2D(reshape(p, patchSize), patchSize);
        patchesreshapedcell = cellfunc(pfn, patchescell);

        % add a line between patches.
        % TODO: make this an option.
        patchesreshapedcellline = cellfunc(@(x) [x; zeros(1, size(x, 2))], patchesreshapedcell);

        % combine along first dimention
        reshapedPatches = cat(1, patchesreshapedcellline{:});
    end
end
