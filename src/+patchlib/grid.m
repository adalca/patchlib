function [idx, newVolSize, gridsize, overlap] = grid(volSize, patchSize, varargin)
% GRID grid of patch starting points for n-d volume
%     idx = grid(volSize, patchSize) computed the grid of patches that fit into volSize given a 
%     particular patchSize, and return the indexes of the top-left voxel of each patch. patchSize
%     should be the same length as volSize. By default, the patches are assumed to be sliding - that
%     is, patches will have an overlap of (patchSize - 1). See below for specifying patch overlaps.
% 
%     The index is in the given volume. If the volume gets cropped as part of the function and you
%     want a linear indexing into the new volume size, use >> newidx = ind2ind(newVolSize, volSize,
%     idx); newVolSize can be passed by the current function, see below.
% 
%     idx = grid(volSize, patchSize, patchOverlap) specifiy the amount of patch overlap. The volume
%     will be cropped to the maximum size that fits the patch grid. For example, a [6x6] volume with
%     a patchsize of [3x3] and overlap of 1 will be cropped to [5x5] volume. Overlap should be <
%     patchSize. patchOverlap should be a scalar (applied to all dim) or the same length as
%     patchSize.
% 
%     To get spacing between non-overlapping patches, enter negative overlaps.
% 
%     idx = grid(volSize, patchSize, kind) allows for pre-specified kind of overlaps: like
%     'sliding', 'discrete', or 'mrf'. see patchlib.overlapkind for details of the supported overlap
%     kinds. If not specified (i.e. function has only 2 inputs), default overlap is 'sliding'.
% 
%     idx = grid(..., patchOverlap/kind, startSub) - start the indexing at a particular location [1
%     x nDims]. This essentially means that the volume will be cropped starting at that location.
%     e.g. if startSub is [2, 2], then only vol(2:end, 2:end) will be included.
% 
%     sub = grid(..., patchOverlap/kind, ..., 'sub') return n-D subscripts instead of linear index.
%     sub will be a 1 x nDim cell. This is equivalent to [sub{:}] = ind2sub(volSize, idx), but is
%     done faster inside this function.
% 
%     [..., newVolSize, nPatches, overlap] = grid(...) returns the size of the cropped volume, the
%     number of patches in each direction, and the size of the overlap. The latter is useful is the
%     'kind' input was used.
% 
%     TODO: could speed up for the special case of 2D or 3D?
%
% See also: overlapkind, gridsize
%
% Contact: {adalca,klbouman}@csail.mit.edu



    % check inputs
    [overlap, startDel, returnsub] = parseinputs(volSize, patchSize, varargin{:});
    [gridsize, newVolSize] = patchlib.gridsize(volSize, patchSize, overlap, startDel);
    nDims = numel(patchSize);

    % compute grid idx
    % prepare the sample grid in each dimension
    step = patchSize - overlap;
    xvec = cell(nDims, 1);
    for i = 1:nDims
        xvec{i} = startDel(i):step(i):(newVolSize(i) + startDel(i) - 1 - (patchSize(i) - 1));
        assert(xvec{i}(end) + patchSize(i) - 1 == ((newVolSize(i) + startDel(i) - 1)));
    end
    
    % get the ndgrid
    % if want subs, this is the faster way to compute (rather than ind -> ind2sub)
    if returnsub
        idx = cell(nDims, 1);
        [idx{:}] = ndgrid(xvec{:});
    else
    
        % if want index, this is the faster way to compute (rather than sub -> sub2ind
        v = reshape(1:prod(volSize), volSize);
        idx = v(xvec{:});
    end
    
end

function [patchOverlap, startDel, retsub] = parseinputs(volSize, patchSize, varargin)

    % check input count, and sizes of elements.
    narginchk(2, 5);
    if isscalar(patchSize)
        patchSize = repmat(patchSize, [1, numel(volSize)]);
    
    else
        assert(numel(volSize) == numel(patchSize), ...
            'volume and patch have different dimensions: %d, %d', numel(volSize), numel(patchSize));
    end
    assert(all(volSize >= patchSize), 'The volume size must be at least as big as the patchSize');

    if nargin == 2
        patchOverlap = 'sliding';
    else
        patchOverlap = varargin{1};
    end
    
    % if patchOverlap is a string, use pre-specified numbers
    if ischar(patchOverlap)
        patchOverlap = patchlib.overlapkind(patchOverlap, patchSize);
    end
    patchSizestr = sprintf(repmat('%d ', [1, numel(patchSize)]), patchSize);
    patchOverlapstr = sprintf(repmat('%d ', [1, numel(patchSize)]), patchOverlap);
    assert(all(patchSize > patchOverlap), ...
        'need: patchSize (%s) > patchOverlap (%s)', patchSizestr, patchOverlapstr);
    
    % startDel
    
    if nargin <= 3 || ischar(varargin{2})
        startDel = ones(size(patchSize));
    else
        startDel = varargin{2};
    end
    
    retsub = false;
    if (nargin == 4 && ischar(varargin{2})) || (nargin == 5)
        if nargin == 4 && ischar(varargin{2})
            assert(strcmp(varargin{2}, 'sub'), 'Char last character must be ''sub''');
        else
            assert(strcmp(varargin{3}, 'sub'), 'Char last character must be ''sub''');
        end
        retsub = true; 
    end
end
