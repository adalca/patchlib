function [gsize, newVolSize, overlap] = gridsize(volSize, patchSize, varargin)
% PATCHCOUNT number of patches that fit into a volume
%   gsize = patchcount(volSize, patchSize) compute the number of patches that fit
%       into volSize given a particular patchSize. patchSize should be the same length as volSize.
%       By default, the patches are assumed to be sliding - that is, patches will have an overlap of
%       (patchSize - 1). See below for specifying patch overlaps.
%
%       To get spacing between non-overlapping patches, enter negative overlaps.
%
%	gsize = patchcount(volSize, patchSize, patchOverlap) The volume will be cropped to
%       the maximum size that fits the patch grid. For example, a [6x6] volume with a patchsize of
%       [3x3] and overlap of 1 will be cropped to [5x5] volume. Overlap should be < patchSize.
%       patchOverlap should be a scalar (applied to all dim) or the same length as patchSize.
%
%   idx = patchcount(volSize, patchSize, kind) allow specification of how the overlap between
%       patches: a scalar, vector (of size [1xnDims]) or a string for a pre-specified configuration,
%       like 'sliding', 'discrete', or 'mrf'. see patchlib.overlapkind for details of the supported
%       overlap kinds. If not specified (i.e. function has only 2 inputs), default overlap is
%       'sliding'.
%
%   idx = patchcount(..., patchOverlap/kind, startSub) - start the indexing at a particular location
%       [1 x nDims]. This essentially means that the volume will be cropped starting at that
%       location. e.g. if startSub is [2, 2], then only vol(2:end, 2:end) will be included.
%
%   [..., newVolSize, overlap] = patchcount(...) returns the size of the cropped volume and the size
%       of the overlap. The latter is useful is the 'kind' input was used.
%
% See Also: grid
%
% Contact: {adalca,klbouman}@csail.mit.edu



    % check inputs
    [overlap, startDel] = parseinputs(volSize, patchSize, varargin{:});
    
    nMiddleVoxels = patchSize - 2 * overlap;
    mVolSize = volSize - startDel + 1;
    
    % compute the number of patches
    repvox = mVolSize - overlap;    % nVoxels in [middle, 1-border] repetitions.
    gsizeComp = repvox ./ (overlap + nMiddleVoxels);
    gsize = floor(gsizeComp);
        
    % new volume size
    newVolSize = gsize .* (overlap + nMiddleVoxels) + overlap;    
end

function [patchOverlap, startDel] = parseinputs(volSize, patchSize, varargin)

    % check input count, and sizes of elements.
    narginchk(2, 4);
    if isscalar(patchSize)
        patchSize = repmat(patchSize, [1, numel(volSize)]);
    
    else
        assert(numel(volSize) == numel(patchSize), ...
            'volume and patch have different dimensions: %d, %d', numel(volSize), numel(patchSize));
    end

    if nargin == 2
        patchOverlap = 'sliding';
    else
        patchOverlap = varargin{1};
    end
    
    % if patchOverlap is a string, use pre-specified numbers
    if ischar(patchOverlap)
        patchOverlap = patchlib.overlapkind(patchOverlap, patchSize);
    end
    assert(all(patchSize > patchOverlap));
    
    if nargin == 3 
        startDel = ones(size(patchSize));
    else
        startDel = varargin{2};
    end
end
