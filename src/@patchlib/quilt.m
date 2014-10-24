function vol = quilt(patches, gridSize, varargin)
% QUILT quilt or reconstruct volume from patch indexes in library
%
%   vol = quilt(patches, gridSize) quilt or reconstruct volume from patches given a grid size. the
%       patch size is guessed based on the given patches 
%
%   vol = quilt(patches, gridSize, patchSize) allows specification of patchSize
%
%   vol = quilt(patches, gridSize, patchSize, patchOverlap) allows specification of patchOverlap
%
%       Inputs (assume nDims = dimensions of the patch/targetvolume and nVoxels = prod(patchSize)):
%       - patches is the library of patches, [M x nVoxels]
%       - gridSize is a [1 x nDims] vector indicating the number of patches in each dimension. We 
%           must have prod(gridSize) == N;
%       - patchSize is a [1 x nDims] vec giving the size of the patch. 
%       - patchOverlap is the amount of overlap between patches, as a scalar, [1 x nDims] vector, 
%           or string. See patchlib.overlapking for the type of strings supported.
%    
%   vol = quilt(..., Param, Value, ...) allows for the following Parameters:
%       'voteAggregator': a function handle to aggregate votes for each voxel. 
%       'weights':  weights for voteAggregator. will normalize to add to 1 accross layers
%       'nWeights': weights already normalized in a specific way
%       'nnAggregator': a function handle to aggregate nn patches.  
%       'nnWeights': weights when doing the nearest neighbor aggregations
%
% Author: adalca@mit

    [patches, gridSize, patchSize, patchOverlap, inputs] = ...
        parseinputs(patches, gridSize, varargin{:});

    % aggregate patches if necessary accross NN 
    if ~isempty(inputs.nnAggregator)
        if ~isempty(inputs.nnWeights)
            if isa(inputs.nnWeights, 'function_handle')
                inputs.nnWeights = inputs.nnWeights(patches);
            end
            wshape = [size(inputs.nnWeights, 1), 1, size(inputs.nnWeights, 2)];
            inputs.nnWeights = reshape(inputs.nnWeights, wshape);
            inputs.nnWeights = repmat(inputs.nnWeights, [1, prod(patchSize), 1]);
            patches = inputs.nnAggregator(patches, inputs.nnWeights);
        else
            patches = inputs.nnAggregator(patches);
        end
    end
    
    % get the votes;
    varargout = cell(1);
    if isempty(inputs.weights) && isempty(inputs.nweights)
        varargout = {};
    end
    [votes, varargout{:}] = patchlib.stackPatches(patches, patchSize, gridSize, patchOverlap{:});

    % use aggregateVotes to vote for the best outcome and get the quiltedIm
    weights = {};
    if ~isempty(inputs.weights) || ~isempty(inputs.nweights)
        % TODO - allow computation of weights via weights function (patches);
        if isa(inputs.weights, 'function_handle')
            weights = inputs.weights(votes, patches);
        else
            % extract weights
            w = ifelse(~isempty(inputs.weights), inputs.weights, inputs.nweights);
            assert(all(size(w) == size(patches)));
            
            % layer the weights according to layer structure.
            idxvec = sub2ind(size(w), varargout{1}(1, :), varargout{1}(2, :));
            weights = nan(size(idxvec));
            weights(~isnan(idxvec)) = w(idxvec(~isnan(idxvec)));
            weights = reshape(weights, size(votes));
        end
        
        % normalize
        if ~isempty(inputs.weights)
            weights = bsxfun(@rdivide, weights, nansum(nansum(weights, 2), 3));
        end
        weights = {weights};
    end
    
    vol = inputs.voteAggregator(votes, weights{:});
    vol = squeeze(vol);
end


function [patches, gridSize, patchSize, patchOverlap, inputs] = ...
    parseinputs(patches, gridSize, varargin)

    narginchk(2, inf);
    
    if numel(varargin) >= 1 && isnumeric(varargin{1})
        patchSize = varargin{1};
        varargin = varargin(2:end);
    else
        patchSize = patchlib.guessPatchSize(size(patches, 2));
    end
    
    patchOverlap = {};
    if isodd(numel(varargin))
        patchOverlap = varargin(1);
        varargin = varargin(2:end);
    end
    
    p = inputParser();
    p.addParameter('voteAggregator', @defaultVoteAggregator, @(x) isa(x, 'function_handle'));
    p.addParameter('nnAggregator', @defaultNNAggregator, @(x) isa(x, 'function_handle'));
    p.addParameter('nnWeights', {});
    p.addParameter('weights', {}, @isnumeric); % provide weights. Will normalize to add to 1 accross layers
    p.addParameter('nweights', {}, @isnumeric); % weights already normalized in a specific way
    p.parse(varargin{:});
    inputs = p.Results;
    assert(isempty(inputs.weights) || isempty(inputs.nweights), ...
        'only weights or nweights should be provided');
    
end

function z = defaultVoteAggregator(varargin)
    z = defaultAggregator(1, varargin{:});
end
   
function z = defaultNNAggregator(varargin)
    z = defaultAggregator(3, varargin{:});
end

function z = defaultAggregator(dim, varargin)
    if numel(varargin) == 1
        z = nanmean(varargin{1}, dim);
    else
        z = nanwmean(varargin{1}, varargin{2}, dim);
    end
end
        
