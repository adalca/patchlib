function [patches, pDst, pIdx, pRefIdxs, srcgridsize, refgridsize] = ...
        volknnsearch(srcvol, refvols, patchSize, varargin)
% VOLKNNSEARCH k-NN search of patches in source given a set of reference volumes
%     patches = volknnsearch(src, refs, patchSize) k-NN search of patches in source volume src given
%     a set of reference volumes refs. refs can be a volume or a cell of volumes, of the same
%     dimentionality as src. patchSize is the size of the patches. patches is a [M x V x K] array,
%     with M being the number of patches, V the number of voxels in a patch, and K from kNN.
% 
%     patches = volknnsearch(src, refs, patchSize, srcPatchOverlap) allows the specification of a
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
%     - 'libfn' (function handle).
%           if you want to use your own library construction method, the signature is:
%           >> libstruct = libfn(inputvol, patchSize, patchOverlap)
%           where inputvol is either srcvol or refvols (as passed in to volknnsearch), and
%           patchOverlap is optional only gets passed if it's passed into volknnsearch.
%           libstruct should be a struct with fields vol, lib, grididx, cropVolSize, gridSize and 
%           optionally refidx
%   
%           Note: if using this option, srcvol and refvols don't actually need to be volumes. For
%           example, they could be pre-computed libstructs, in which case one can use 
%           >> libfn = @(x, y, z) x; 
%
%     - 'excludePatches' (default: false);
%
%     - 'separateProc' (default: 0)
%           0 - no separate processing 
%           1 - separately process each reference and gather the results
%               at the end - saves a bit of memory but might be a bit slower due to overhead
%           [TODO: NOT IMPLEMENTED] X for X > 10 - separate by reference and do separate knnsearches
%           where each call is 
%     - 'separateProcAgg' (default: agg) agg or sep.
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
    [refvolscell, srcoverlap, refoverlap, knnvarargin, inputs] = ...
        parseinputs(refvols, patchSize, varargin{:});
    
    % if processing references separately
    nRefs = numel(refvolscell); % guaranteed refvolscell is a cell.
    if inputs.separateProc == 1 && nRefs > 1
        vargout = cell(nRefs, 1);
        
        % exclude patches in this mode. Will build the patches at the end, if necessary.
        f = find(strcmp('excludePatches', varargin));
        if ~isempty(f) 
            varargin{f + 1} = true;
        else
            varargin{end + 1} = 'excludePatches';
            varargin{end + 1} = true;
        end
        
        % do the search
        srcpass = prepsrc(srcvol, patchSize, inputs, srcoverlap{:});
        for i = 1:nRefs
            i
            vargout{i} = cell(6, 1);
            [vargout{i}{:}] = patchlib.volknnsearch(srcpass, refvols{i}, patchSize, varargin{:});
            vargout{i}{1} = [];
        end
        
        % combine the results
        [pDst, pIdx, pRefIdxs, srcgridsize, refgridsize] = volknnaggresults(vargout, inputs);
        
        % get the patches if necessary. Note, this is slower than if we got the patches originally
        % with the volknnsearch mode, but that can lead to memory issues in large numbers of
        % references (since you're getting a factor of nRefs more patches than you need, which can
        % grow quickly). Since separateProc is a low-memory mode, we choose this path.
        patches = [];
        if ~inputs.excludePatches
            src = prepsrc(srcvol, patchSize, inputs, srcoverlap{:});
            libfn = @(x, y) getfield(inputs.libfn(x, patchSize, refoverlap{:}), 'lib'); %#ok<GFLD>
            patches = getpatches(src, refvolscell, patchSize, pIdx, pRefIdxs, libfn);
        end
        return
    end
    
    % compute source library
    src = prepsrc(srcvol, patchSize, inputs, srcoverlap{:});
    assert(size(src.lib, 1) > 0, 'Source library is empty');
    
    % build reference the libraries
    if inputs.buildreflibs
        refs = inputs.libfn(refvolscell, patchSize, refoverlap{:});
    end

    if ~isempty(inputs.location)
        % TODO: add nDim location support.
        [src, refs] = addlocation(src, refs, inputs.location);
    end

    % compute
    [pIdx, pRefIdxs, pDst] = inputs.searchfn(src, refs, knnvarargin{:});
    srcgridsize = src.gridSize;

    % extract the patches
    if inputs.excludePatches
        patches = [];
    else
        patches = getpatches(src, refs, patchSize, pIdx, pRefIdxs);
    end

    refgridsize = refs(1).gridSize;    
end

function src = prepsrc(srcvol, patchSize, inputs, varargin)
    
    if isstruct(srcvol) && isfield(srcvol, 'lib'); 
        warning('doing src trick');
        src = srcvol;
    else
        src = inputs.libfn(srcvol, patchSize, varargin{:});
    end
    src.mask = ifelse(isempty(inputs.mask), true(size(src.vol)), inputs.mask);
end

function patches = getpatches(src, refs, patchSize, pIdx, pRefIdxs, varargin)
% patches = getpatches(src, refs, patchSize, pIdx, pRefIdxs) or
% patches = getpatches(src, refs, patchSize, pIdx, pRefIdxs, libfn)
% TODO: what about the patchOverlap? need to pass this in as well? ot ro lib2patches

    mask = src.mask(src.grididx);
    
    if ~isempty(varargin)
        pm = patchlib.lib2patches(refs, pIdx(mask, :, :), pRefIdxs(mask, :, :), patchSize, varargin{:});
    else
        refslibs = cellfunc(@(x) x(:, 1:prod(patchSize)), {refs.lib});
        pm = patchlib.lib2patches(refslibs, pIdx(mask, :, :), pRefIdxs(mask, :, :), patchSize);
    end
    
    % TODO - unsure. if mask is *very* small compared to the volume, might need to work in
    % sparse? but then, most other functions need to worry about memory as well.
    if sum(~mask(:)) > 0
        patches = maskvox2vol(pm, mask, @sparse);
    else
        patches = pm;
    end

end

function [src, refs] = addlocation(src, refs, locwt)
% adds location subscripts to the src + refs libraries.
    srcsub = size2sub(size(src.vol));
    srcvec = cat(2, srcsub{:});
    src.lib = [src.lib, bsxfun(@times, locwt, srcvec(src.grididx, :))];

    refsub = cellfunc(@(x) size2sub(size(x)), {refs.vol});
    refvecs = cellfunc(@(x) cat(2, x{:}), refsub);
    refvecssel = cellfunc(@(x, y) x(y, :), refvecs, {refs.grididx});
    refsubvec = cellfunc(@(x) bsxfun(@times, locwt, x), refvecssel);
    fullreflib = cellfunc(@horzcat, {refs.lib}, refsubvec);
    [refs.lib] = fullreflib{:};
end

function volstruct = vol2libwrap(vol, patchSize, varargin)
        
    % vol2lib
    refidx = cell(1*iscell(vol));
    [lib, grididx, cropVolSize, gridSize, refidx{:}] = ...
        patchlib.vol2lib(vol, patchSize, varargin{:});
        
    % build struct. note that if lib is a cell, all elements should be a cell
    volstruct = structrich(vol, lib, grididx, cropVolSize, gridSize);
    
    % assignrefidx
    if ~isempty(refidx)
        [volstruct.refidx] = refidx{1}{:};
    end
end


function [refs, srcoverlap, refoverlap, knnvargin, inputs] = parseinputs(refs, patchSize, varargin)
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
    p.addParameter('local', [], @isnumeric);
    p.addParameter('location', 0, @isnumeric);
    p.addParameter('searchfn', [], @(x) isa(x, 'function_handle'));
    p.addParameter('buildreflibs', true, @islogical);
    p.addParameter('excludePatches', false, @islogical);
    p.addParameter('mask', [], @islogical);
    p.addParameter('separateProc', 0, @isnumeric); % see help
    p.addParameter('separateProcAgg', 'agg', @(x) validatestring(x, 'agg', 'sep')); % see help
    p.addParameter('libfn', @vol2libwrap, @(x) isa(x, 'function_handle'));
    p.addParameter('verbose', false, @islogical);
    p.KeepUnmatched = true;
    p.parse(varargin{:});
    knnvargin = struct2cellWithNames(p.Unmatched);
    inputs = p.Results; 
    
    % make sure refs is a cell
    if ~iscell(refs)
        refs = {refs};
    end
    nDims = numel(patchSize);
    
    
    if isempty(inputs.local) && isempty(inputs.searchfn)
        assert(inputs.buildreflibs)
        inputs.searchfn = @volknnglobalsearch;
    end
    
    if ~isempty(inputs.local)
        assert(inputs.buildreflibs);
        assert(isnumeric(inputs.local));
        assert(isempty(inputs.searchfn), 'Only provide local spacing or search function, not both');
        if isscalar(inputs.local), inputs.local = inputs.local * ones(1, nDims); end
        inputs.searchfn = @(x, y, varargin) volknnlocalsearch(x, y, inputs.local, varargin{:});
    end    
    
    if isscalar(inputs.location)
        inputs.location = repmat(inputs.location, [1, nDims]);
    end
end
