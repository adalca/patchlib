function volSize = grid2volSize(gridSize, patchSize, varargin)
% NPATCHES2VOLSIZE volume size from number of patches
%     volSize = grid2volSize(gridSize, patchSize) compute the size of a volume of patches given the
%     patch size and number of patches. This assumes sliding patches (i.e. patch overlap of
%     patchSize - 1)
% 
%     volSize = grid2volSize(gridSize, patchSize, patchOverlap) allows for the specification of
%     amount of patch overlap.
% 
%     volSize = grid2volSize(gridSize, patchSize, kind) allows for pre-specified kind of overlaps:
%     like 'sliding', 'discrete', or 'mrf'. see patchlib.overlapkind for details of the supported
%     overlap kinds. If not specified (i.e. function has only 2 inputs), default overlap is
%     'sliding'.
%
% See Also: gridsize, grid, overlapkind
%
% Contact: {adalca,klbouman}@csail.mit.edu
    
    narginchk(2, 3)
    if nargin == 2
        patchOverlap = patchSize - 1;
    else
        patchOverlap = varargin{1};
        if ischar(patchOverlap)
            patchOverlap = patchlib.overlapkind(patchOverlap, patchSize);
        end
    end
    
    volSize  = (patchSize - patchOverlap) .* gridSize + patchOverlap;
    
