function [patches, pDst, pIdx, pRefIdxs, srcgridsize, refgridsize] = ...
        volknnsearch(srcvol, refvols, patchSize, varargin)
% VOLKNNSEARCH k-NN search of patches in source given a set of reference volumes
%     patches = volknnsearch(src, refs, patchSize) k-NN search of patches in source volume src given
%     a set of reference volumes refs. refs can be a volume or a cell of volumes, of the same
%     dimentionality as src. patchSize is the size of the patches. patches is a [M x V x K] array,
%     with M being the number of patches, V the number of voxels in a patch, and K from kNN.
% 
%     patches = volknnsearch(src, refs, patchSize, patchOverlap) allows the specification of a
%     patchOverlap amount or kind for src. See patchlib.overlapkind for more information. Default is
%     the default used in patchlib.vol2lib.
% 
%     patches = volknnsearch(src, refs, patchSize, srcPatchOverlap, refsPatchOverlap) allows the
%     specification of a patchOverlap amount or kind for refs as well.
% 
%     patches = volknnsearch(..., Param, Value) allows for parameter/value pairs:
%     - 'local' (voxel spacing integer): if desired to do local search around each voxel, instead of
%       global (which is default).
%       
%     - 'searchfn': function handle --- allow for a different type of local search, rather than the
%       standard local or global search functions. For example, this can be useful if you want to do
%       a local search in some registration space, where the source location of a voxel corresponds
%       to a different locationin each source. The function signature is (src, refs, patchSize,
%       knnvarargin), where src is a struct with fields vol, lib, grididx, cropVolSize and gridSize
%       and refs is a structs with fields vols, lib, grididx, cropVolSize, gridSize, refidx -- all
%       cells of size nRefs x 1
%
%     - 'location' - a location based weight. the location of each voxel (in spatial coordinates) is
%       added to the feature vector, times the factor passed in via 'location'. default is 0
%       (location does not factor in). scalar or [1 x nDims] vector. 
%
%     - 'buildreflibs': logical (default: true) on whether to pre-compute the reference libraries
%       (which can take space and memory). This must stay true for the default global or local
%       search functions.
%
%     - 'mask' logical mask the size of the source vol, volknnsearch will only run for voxels where
%       mask is true
%
%     - 'passlibstruct' (default: false);
%   
%     - any Param/Value argument for knnsearch.
%
%     [patches, pDst, pIdx, pRefIdx, srcgridsize, refgridsize] = volknnsearch(...) also returns  the
%     patch indexes (M x K) into the reference libraries (i.e. matching refgridsize, *not* the
%     entire reference volume(s)), pRefIdxs (Mx1) indexing the libraries for every patch, and pDst
%     giving the distance of every patch resulting from knnsearch(). srcgridsize is the source grid
%     size. refgridsize is the grid size of each ref (a cell if refs was cell, a vector otherwise.
%
% Contact: adalca@csail.mit.edu

    % parse inputs
    narginchk(3, inf);
    [refs.vols, srcoverlap, refoverlap, knnvarargin, inputs] = parseinputs(refvols, varargin{:});
    
    % source library
    if inputs.passlibstruct
        src = srcvol;
    else 
        src.vol = srcvol;
        [src.lib, src.grididx, src.cropVolSize, src.gridSize] = ...
            patchlib.vol2lib(srcvol, patchSize, srcoverlap{:});
    end
    src.mask = ifelse(isempty(inputs.mask), true(size(src.vol)), inputs.mask);
    
    % build reference the libraries
    if inputs.buildreflibs
        if inputs.passlibstruct
            refs = refs.vols;
        else
            [refs.lib, refs.grididx, refs.cropVolSize, refs.gridSize, refs.refidx] = ...
                patchlib.vol2lib(refs.vols, patchSize, refoverlap{:});
        end
    end
    
    if inputs.location
        % TODO: add nDim location support.
        [src, refs] = addlocation(src, refs, inputs.location);
    end
    
    % compute
    [pIdx, pRefIdxs, pDst] = inputs.searchfn(src, refs, knnvarargin{:});
    srcgridsize = src.gridSize;
    
    % extract the patches
    mask = src.mask(src.grididx);
    refslibs = cellfun(@(x) x(:, 1:prod(patchSize)), refs.lib, 'UniformOutput', false);
    patchesm = patchlib.lib2patches(refslibs, pIdx(mask, :, :), pRefIdxs(mask, :, :), patchSize);
    % TODO - unsure. if mask is *very* small compared to the volume, might need to work in sparse?
    % but then, most other functions need to worry about memory as well.
    if sum(~mask(:)) > 0
        patches = maskvox2vol(patchesm, mask, @sparse);
    else
        patches = patchesm;
    end
    
    if iscell(refvols)
        refgridsize = refs.gridSize;
    else
        refgridsize = refs.gridSize{1};
    end
end

function [pIdx, pRefIdxs, pDst] = localsearch(src, refs, spacing, varargin)
% perform a global search, with <spacing> around each voxel in each ref included in the search for
% knn for that voxel.

    nRefs = numel(refs.vols);
    
    % get subscripts refs.subs that match the linear index in refs
    fn = @(x, y) ind2subvec(size(x), y(:));
    refs.subs = cellfun(fn, refs.vols(:), refs.grididx(:), 'UniformOutput', false);

    % get the linear indexes grididx from full volume space to gridSize
    fn = @(x, y, z) reshape(ind2ind(size(x), y, z), y);
    ridx = cellfun(fn, refs.vols(:), refs.gridSize(:), refs.grididx(:), 'UniformOutput', false);
    
    % get subscript local ranges for each voxel. 
    % Pre-computation should save time inside the main for-loop
    srcgridsub = ind2subvec(size(src.vol), src.grididx(:));
    mingridsub = max(bsxfun(@minus, srcgridsub, spacing), 1);
    fn = @(x) bsxfun(@min, bsxfun(@plus, srcgridsub, spacing), x);
    maxgridsub = cellfun(fn, refs.gridSize, 'UniformOutput', false);
    
    % get input K
    f = find(strcmp('K', varargin), 1, 'first');
    K = ifelse(isempty(f), '1', 'varargin{f + 1}', true);
        
    % go through each voxel, get reference patches from nearby from each reference.
    pIdx = nan(size(src.lib, 1), K);
    pRefIdxs = nan(size(src.lib, 1), K);
    pDst = nan(size(src.lib, 1), K);
    subset = find(src.mask(src.grididx))';
    for i = subset %1:size(src.lib, 1)
        
        % compute the reference linear idx and reference number for the regions around this voxel
        ridxwindow = cell(nRefs, 1);
        ipatches = cell(nRefs, 1);
        refIdx = cell(nRefs, 1);
        for r = 1:nRefs
            idxsel = bsxfun(@ge, refs.subs{r}, mingridsub(i, :)) & ...
                bsxfun(@le, refs.subs{r}, maxgridsub{r}(i, :));
            ridxwindow{r} = ridx{r}(all(idxsel, 2));
            ridxwindow{r} = ridxwindow{r}(:);    
            
            ipatches{r} = refs.lib{r}(ridxwindow{r}, :);
            refIdx{r} = r * ones(size(ridxwindow{r}));
        end
        gidxsall = cat(1, ridxwindow{:});        
        ipatchesall = cat(1, ipatches{:});
        riall = cat(1, refIdx{:});
        assert(size(gidxsall, 1) >= K, 'Spacing does not allow %d nearest neighbours', K);
        
        [p, d] = knnsearch(ipatchesall, src.lib(i, :), varargin{:});
        
        pIdx(i, :) = gidxsall(p);
        pDst(i, :) = d; 
        pRefIdxs(i, :) = riall(p);
    end
end

function [pIdx, pRefIdxs, pDst] = globalsearch(src, refs, varargin)
% do a global search

    % compute one ref library, and associated indexes
    refslib = cat(1, refs.lib{:});
    refsidx = cat(1, refs.refidx{:});
       
    % do knn
    mask = src.mask(src.grididx);
    [pIdxm, pDstm] = knnsearch(refslib, src.lib(mask, :), varargin{:});
    pRefIdxsm = refsidx(pIdxm);
    pRefIdxsm = reshape(pRefIdxsm, size(pIdxm)); % necessary if size(pIdxm, 1) == 1;
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
    sizes = cellfun(@(x) size(x, 1), refs.lib);
    for i = 1:numel(refs.lib)
        pIdx(pRefIdxs == i) = pIdx(pRefIdxs == i) - sum(sizes(1:i-1));
    end
end

function [src, refs] = addlocation(src, refs, locwt)
% adds location subscripts to the src + refs libraries.
    srcsub = size2sub(size(src.vol));
    srcvec = cat(2, srcsub{:});
    src.lib = [src.lib, bsxfun(@times, locwt, srcvec(src.grididx, :))];

    refsub = cellfun(@(x) size2sub(size(x)), refs.vols, 'UniformOutput', false);
    refvecs = cellfun(@(x) cat(2, x{:}), refsub, 'UniformOutput', false);
    refvecssel = cellfun(@(x, y) x(y, :), refvecs, refs.grididx, 'UniformOutput', false);
    refsubvec = cellfun(@(x) bsxfun(@times, locwt, x), refvecssel, 'UniformOutput', false);
    refs.lib = cellfun(@horzcat, refs.lib, refsubvec, 'UniformOutput', false);
end

function [refs, srcoverlap, refoverlap, knnvargin, inputs] = parseinputs(refs, varargin)
% getPatchFunction (2dLocation_in_src, ref), 
% method for extracting the actual stuff - this can probably be put with getPatchFunction. 
% pre-sel voxels?
% Other stuff for knnsearch
    

    
    % check for source overlaps
    srcoverlap = {};
    if numel(varargin) > 1 && patchlib.isvalidoverlap(varargin{1})
        srcoverlap = varargin(1);
        varargin = varargin(2:end);
    end
    
    % check for reference overlaps
    refoverlap = {};
    if numel(varargin) > 1 && patchlib.isvalidoverlap(varargin{1})
        refoverlap = varargin(1);
        varargin = varargin(2:end);
    end
    
    % 'local' means local search, and takes in spacing or function. 
    % also allow 'localpreprocess'
    p = inputParser();
    p.addParameter('passlibstruct', false, @islogical);
    p.addParameter('local', [], @isnumeric);
    p.addParameter('location', 0, @isnumeric);
    p.addParameter('searchfn', [], @(x) isa(x, 'function_handle'));
    p.addParameter('buildreflibs', true, @islogical);
    p.addParameter('mask', [], @islogical);
    p.KeepUnmatched = true;
    p.parse(varargin{:});
    knnvargin = struct2cellWithNames(p.Unmatched);
    inputs = p.Results;
    
    if inputs.passlibstruct
        nDims = ndims(refs.vols{1});
    else
        if ~iscell(refs)
            refs = {refs};
        end
        nDims = ndims(refs{1});
    end
    
    if isempty(inputs.local) && isempty(inputs.searchfn)
        assert(inputs.buildreflibs)
        inputs.searchfn = @globalsearch;
    end
    
    if ~isempty(inputs.local)
        assert(inputs.buildreflibs);
        assert(isnumeric(inputs.local));
        assert(isempty(inputs.searchfn), 'Only provide local spacing or search function, not both');
        if isscalar(inputs.local), inputs.local = inputs.local * ones(1, nDims); end
        inputs.searchfn = @(x, y, varargin) localsearch(x, y, inputs.local, varargin{:});
    end    
    
    if isscalar(inputs.location)
        inputs.location = repmat(inputs.location, [1, nDims]);
    end
end
