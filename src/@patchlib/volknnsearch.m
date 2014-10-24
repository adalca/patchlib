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
%     - 'buildreflibs': logical (default: true) on whether to pre-compute the reference libraries
%       (which can take space and memory). This must stay true for the default global or local
%       search functions.
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
    src.vol = srcvol;
    [src.lib, src.grididx, src.cropVolSize, src.gridSize] = ...
        patchlib.vol2lib(srcvol, patchSize, srcoverlap{:});
    
    % build reference the libraries
    if inputs.buildreflibs
        [refs.lib, refs.grididx, refs.cropVolSize, refs.gridSize, refs.refidx] = ...
            patchlib.vol2lib(refs.vols, patchSize, refoverlap{:});
    end
    
    % compute
    [patches, pDst, pIdx, pRefIdxs] = ...
        inputs.searchfn(src, refs, patchSize, knnvarargin{:});
    srcgridsize = src.gridSize;
    
    if iscell(refvols)
        refgridsize = refs.gridSize;
    else
        refgridsize = refs.gridSize{1};
    end
    
end



function [patches, pDst, pIdx, pRefIdxs] = localsearch(src, refs, patchSize, spacing, varargin)
% perform a global search, with <spacing> around each voxel in each ref included in the search for
% knn for that voxel.

    nRefs = numel(refs.vols);
    
    % get subscript instead of linear index in refs:
    for i = 1:nRefs
        refs.subs{i} = ind2subvec(size(refs.vols{i}), refs.grididx{i}(:));
    end

    % get the linear indexes in the grididx
    ridx = cell(nRefs, 1);    
    for i = 1:nRefs
        ridx{i} = ind2ind(size(refs.vols{i}), refs.gridSize{i}, refs.grididx{i});
        ridx{i} = reshape(ridx{i}, refs.gridSize{i});
    end
    
    % get subscript ranges for each voxel. Pre-computation should save time inside the main for loop
    sub = ind2subvec(size(src.vol), src.grididx(:));
    sub1 = max(bsxfun(@minus, sub, spacing), 1);
    sub2 = cell(nRefs, 1);
    for r = 1:numel(refs.lib)
        sub2{r} = bsxfun(@min, bsxfun(@plus, sub, spacing), refs.gridSize{r});
    end
    
    % get K
    f = find(strcmp('K', varargin), 1, 'first');
    K = ifelse(isempty(f), '1', 'varargin{f + 1}', true);
    
    % go through each voxel, get reference patches from nearby from each reference.
    pIdx = zeros(size(src.lib, 1), K);
    pRefIdxs = zeros(size(src.lib, 1), K);
    pDst = zeros(size(src.lib, 1), K);
    for i = 1:size(src.lib, 1)
        
        % compute the reference linear idx and reference number for the regions around this voxel
        gidx = cell(nRefs, 1);
        ipatches = cell(nRefs, 1);
        refIdx = cell(nRefs, 1);
        for r = 1:nRefs
            idxsel = bsxfun(@ge, refs.subs{r}, sub1(i, :)) & bsxfun(@le, refs.subs{r}, sub2{r}(i, :));
            gidx{r} = ridx{r}(all(idxsel, 2));
            gidx{r} = gidx{r}(:);    
            
            ipatches{r} = refs.lib{r}(gidx{r}, :);
            refIdx{r} = r * ones(size(gidx{r}));
            
        end
        gidxsall = cat(1, gidx{:});        
        ipatchesall = cat(1, ipatches{:});
        riall = cat(1, refIdx{:});
        assert(size(gidxsall, 1) >= K, 'Spacing does not allow %d nearest neighbours', K);
        
        [p, d] = knnsearch(ipatchesall, src.lib(i, :), varargin{:});
        pIdx(i, :) = gidxsall(p);
        pDst(i, :) = d; 
        pRefIdxs(i, :) = riall(p);
    end

    % extract the patches
    patches = patchlib.lib2patches(refs.lib, pIdx, pRefIdxs, patchSize);
end



function [patches, pDst, pIdx, pRefIdxs] = globalsearch(src, refs, patchSize, varargin)
% do a global search

    % compute one ref library, and associated indexes
    refslib = cat(1, refs.lib{:});
    refsidx = cat(1, refs.refidx{:});
    
    % do knn
    [pIdx, pDst] = knnsearch(refslib, src.lib, varargin{:});
    pRefIdxs = refsidx(pIdx);
    
    % fix pIdx for return
    sizes = cellfun(@(x) size(x, 1), refs.lib);
    for i = 1:numel(refs.lib)
        pIdx(pRefIdxs == i) = pIdx(pRefIdxs == i) - sum(sizes(1:i-1));
    end
    
    % return patches
    patches = patchlib.lib2patches(refs.lib, pIdx, pRefIdxs, patchSize);
end



function [refs, srcoverlap, refoverlap, knnvargin, inputs] = parseinputs(refs, varargin)
% getPatchFunction (2dLocation_in_src, ref), 
% method for extracting the actual stuff - this can probably be put with getPatchFunction. 
% pre-sel voxels?
% Other stuff for knnsearch
    
    if ~iscell(refs)
        refs = {refs};
    end
    
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
    p.addParameter('local', [], @isnumeric);
    p.addParameter('searchfn', [], @(x) isa(x, 'function_handle'));
    p.addParameter('buildreflibs', true, @islogical);
    p.KeepUnmatched = true;
    p.parse(varargin{:});
    knnvargin = struct2cellWithNames(p.Unmatched);
    inputs = p.Results;
    
    if isempty(inputs.local) && isempty(inputs.searchfn)
        assert(inputs.buildreflibs)
        inputs.searchfn = @globalsearch;
    elseif ~isempty(inputs.local)
        assert(inputs.buildreflibs);
        assert(isnumeric(inputs.local));
        assert(isempty(inputs.searchfn), 'Only provide local spacing or search function, not both');
        inputs.searchfn = @(x, y, z, varargin) localsearch(x, y, z, inputs.local, varargin{:});
    end
end
