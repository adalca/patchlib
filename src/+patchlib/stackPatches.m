function varargout = stackPatches(patches, patchSize, gridSize, varargin)
% STACKPATCHES stack patches in layer structure
%   layers = stackPatches(patches, patchSize, gridSize) stack given patches in a layer structure.
%   patches is [N x V x K], with patches(i, :, 1:K) indicates K patch candidates at location i (e.g.
%   the result of a 3-nearest neightbours search). patchSize and gridSize are vectors, V =
%   prod(patchSize) and N = prod(gridSize). patches are assumed to have a 'sliding' overlap (i.e.
%   patchSize - 1) -- see below for specifying overlap amounts.
%
%   layers is a [nLayers x targetSize x K] array, with nLayers that are the size of the desired
%   target (i.e. once the patches are positioned to fit the grid). The first layer, essentially
%   stacks the first patch, then the next non-overlapping patch, and so on. The second layer takes
%   the first non-stacked patch, and then the next non-overlapping patch, and so on until we run out
%   of patches. 
%       
%   Together, patchSize, gridSize and the patch overlap (see below), indicate how the patches will
%   be layed out and what the target layer size will be.
%   
%   For more information about the interplay between patchSize, gridSize and patchOverlap, see
%   patchlib.grid.
%
%   layers = stackPatches(patches, patchSize, targetSize) allows for the specification of the target
%   image size instead of the gridSize.
%
%   layers = stackPatches(..., patchOverlap) allows for the specification of patch overlap amount or
%   kind. Default is 'sliding'. see patchlib.overlapkind for more information
%
%   [layers, idxmat, pLayerIdx] = stackPatches(...) also returns idxmat, a matrix the same size as
%   'layers' containing linear indexes into the inputted patches matrix. This is useful, for
%   example, to create a layer structure of patch weights to match the patches layer structure.
%   idxmat is [2 x N x targetSize x K], with idxmat(1, :) giving patch ids, and idxmat(2, :) giving
%   voxel ids. pLayerIdx is a [V x 1] vector indicating the layer index of each input patch.
%   See example in patchlib.quilt code.
%   
% Contact: {adalca,klbouman}@csail.mit.edu
    
    % input checking
    narginchk(3, 4);
    K = size(patches, 3);  
        
    % compute the targetsize and target
    if prod(gridSize) == size(patches, 1)
        intargetSize = patchlib.grid2volSize(gridSize, patchSize, varargin{:});
    else
        intargetSize = gridSize;
    end  
    
    % compute the targetsize and target
    [grididx, targetSize] = patchlib.grid(intargetSize, patchSize, varargin{:});
    assert(all(intargetSize == targetSize), 'The grid does not match the provided target size');
    
    % prepare subscript and index vectors
    allSub = ind2subvec(targetSize, grididx(:));
    allIdx = 1:numel(grididx);

    % get index of layer location so that patches don't overlap
    modIdx = num2cell(modBase(allSub, repmat(patchSize, [size(allSub, 1), 1])), 1);
    pLayerIdx = sub2ind(patchSize, modIdx{:})';
    
    % initiate the votes layer structure
    layerIds = unique(pLayerIdx);
    nLayers = numel(layerIds);
    layers = nan([nLayers, targetSize, K]);
    if nargout >= 2
        idxmat = nan([2, nLayers, targetSize, K]);
    end
    
    % go over each layer index
    for layerIdx = 1:nLayers % parfor
        pLayer = find(pLayerIdx == layerIds(layerIdx));

        layerVotes = nan([targetSize, K]);
        if nargout >= 2
            layerIdxMat = nan([2, targetSize, K]);
        end
        for pidx = 1:length(pLayer)
            p = pLayer(pidx);
            idx = allIdx(p);
            
            localpatches = squeeze(patches(p, :, :));
            
            % extract the patch and insert into the layers
            patch = reshape(localpatches, [patchSize, K]);
            sub = [allSub(p, :), 1];
            endSub = sub + [patchSize, K] - 1;
            layerVotes = actionSubArray('insert', layerVotes, sub, endSub, patch);
            
            if nargout >= 2
                locidx = repmat(idx, [2, patchSize, K]);
                locidx(2, :) = repmat((1:prod(patchSize))', [K, 1]);
                endSub = sub + [patchSize, K] - 1;
                layerIdxMat = actionSubArray('insert', layerIdxMat, [1, sub], [2, endSub], locidx);
            end
        end
        layers(layerIdx, :) = layerVotes(:);
        if nargout >= 2
            idxmat(1, layerIdx, :) = layerIdxMat(1, :);
            idxmat(2, layerIdx, :) = layerIdxMat(2, :);
        end
    end
    
    % setup outputs
    varargout{1} = layers;
    
    if nargout >= 2
%         idxmat = shiftdim(idxmat, ndims(idxmat) - 1);
        varargout{2} = idxmat;
    end
    
    if nargout == 3
        p = zeros(1, max(pLayerIdx(:)));
        p(layerIds) = 1:numel(layerIds);
        varargout{3} = p(pLayerIdx);
    end
end
