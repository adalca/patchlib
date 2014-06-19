function [patchesCell, patchSize] = patchesmat2cell(patches, patchSize)
% in development
%   patches is N x V
%   patchesCell is cell of N patches formatted with patchSize.
%   is patchSize is not given, it's guessed. 

    if nargin == 1
        patchSize = patchlib.guessPatchSize(size(patches, 2), 2);
    end
    
    nPatches = size(patches, 1);
    patchesCell = cell(nPatches, 1);
    for i = 1:nPatches
        patchesCell{i} = reshape(patches(i, :), patchSize);
    end
    