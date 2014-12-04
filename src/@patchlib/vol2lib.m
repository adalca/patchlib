function varargout = vol2lib(vol, patchSize, varargin)
% VOL2LIB transform a volume into a patch library
%   lib = vol2lib(vol, patchSize) transform volume vol to a patch library. vol can be any dimensions
%   (tested for 2, 3); patchSize is the size of the patch (nDims x 1 vector). The default assumption
%   is that the patches overlap by (patchSize - 1) (i.e. 'sliding' patches). See below for options
%   on changing this. The size of the library is then the number of patches that fit in the image x
%   number of voxels in the patch.
%
%   Alternatively, vol can be a cell array of volumes, in which case the library is computed for
%   each volumes. library is then a cell array with as many entries as volumes.
%
%   lib = vol2lib(vol, patchSize, overlap) allow specification of how the overlap between patches: a
%   scalar, vector (of size [1xnDims]) or a string for a pre-specified configuration, like
%   'sliding', 'discrete', or 'mrf'. see patchlib.overlapkind for details of the supported overlap
%   kinds. If not specified (i.e. function has only 2 inputs), default overlap is 'sliding'.
%
%   Note: vol2lib will cut the volume to fit the right number of patches.
%
%   [lib, idx, libVolSize, gridSize] = vol2lib(...) returns the index of the starting (top-left)
%   point of every patch in the *original* volume, and the size of the volumes size, which is
%   smaller than or equal to the size of vol. It will be smaller than the initial volume if the
%   volume had to be cropped. Also returns the number of patches gridSize.
%
%   [..., libIdx] = vol2lib(...) only given a cell of vols, returns a cell array with each entry
%   being a column vector with the same number of rows as library, indicating the volume index (i.e.
%   1..numel(vols))
%
%   [libfile, idx, libVolSize, gridSize] = vol2lib(..., 'savefile', 'filename.mat') allows for
%   partial computations with parital save/load to the savefile filename.mat. This is an idea option
%   for huge libraries that don't (or barely do) fit in memory --- the function will work with
%   matfile() to dynamically read or write parts of the necessariy variables to disc. Instead of
%   returning library, a matfile pointer, libfile, will be returned. At this point, typing
%   libfile.lib will load the library into memory. Since you probably had memory constraints,
%   you may want to load the library in parts, just as libfile.lib(1, :), etc.
%
%   Current Algorithm:
%       Initiate by getting a first 'grid' of the top left index of every patch
%       Iterate: shift through all the indexes in a patch (1:prod(patchSize)) 
%       - get the appropriate grid
%           e.g. the second iteration gives us the second point in every patch
%       - stack the grids [horzcat] in a library of indexes
%       use this library of indexes to index into the volume, giving the final library
%   This method was optimized over several versions. History of performance:
%       for 1000 smaller calls: ~2.7s --> down to 0.7s
%       for 10 big calls: 4.7s --> 2.5s
%
%   TODO: could speed up for the special case of 2D or 3D?
%
% See Also: grid, im2col, ifelse
%
% Contact: {adalca,klbouman}@csail.mit.edu
   
    % if vol is a cell, recursively compute the libraries for each cell. 
    if iscell(vol)
        varargout = cell(nargout, 1);
        [varargout{:}] = vol2libcell(vol, patchSize, varargin{:});
        return
    end
    
    % inputs
    [patchOverlap, dofiledrop, dropfile, memory] = parseInputs(varargin{:});
    nDims = ndims(vol);
    volSize = size(vol);
    
    % get the index and subscript of the initial grid
    [grididx, cropVolSize, gridSize] = patchlib.grid(volSize, patchSize, patchOverlap{:}); 
    initsub = cell(1, nDims);
    [initsub{:}] = ind2sub(volSize, grididx);
    vol = cropVolume(vol, cropVolSize);
    
    % get all of the shifts in a [prod(patchSize) x nDims] subscript matrix
    shift = cell(1, nDims);
    [shift{:}] = ind2sub(patchSize, (1:prod(patchSize))');
    shift = [shift{:}];
    
    % compute the actual library
    if ~dofiledrop
        library = memlib(vol, patchSize, cropVolSize, initsub, shift);
        libsize = size(library);
        outlib = library;
    else
        filelib(vol, patchSize, cropVolSize, initsub, shift, dropfile, memory{:});
        dropfile.grididx = grididx(:);
        dropfile.cropVolSize = cropVolSize;
        dropfile.gridSize = gridSize;
        libsize = size(dropfile, 'lib');
        outlib = dropfile;
    end
    
    % check final library size
    assert(numel(grididx) == libsize(1), ...
        'Something went wrong with the library of index computation. Sizes don''t match.');
    assert(prod(gridSize) == libsize(1), ...
        'Something went wrong with the library of index computation. Sizes don''t match.');
    
    % outputs 
    outputs = {outlib, grididx(:), cropVolSize, gridSize};
    varargout = outputs(1:nargout); 
end

function library = memlib(vol, patchSize, cropVolSize, initsub, shift)
% compute library in memory

    % initialize library of subscripts into the volume
    nDims = ndims(vol);
    nGridVoxels = numel(initsub{1});
    sub = cell(nDims, 1);
    sub(:) = {zeros(nGridVoxels, prod(patchSize), 'uint32')};
   
    % update subscript library
    for dim = 1:nDims
        
        % go through each shift
        for s = 1:prod(patchSize)
            sub{dim}(:, s) = initsub{dim}(:) + shift(s, dim) - 1;
        end
        
        % put the subscript library in a vector
        sub{dim} = sub{dim}(:);
    end
    
    % compute the library of linear indexes into the volume
    idxvec = sub2ind(cropVolSize, sub{:});
    clear sub;

    % compute final library
    library = vol(idxvec(:));
    library = reshape(library, [nGridVoxels, prod(patchSize)]);
end


function filelib(vol, patchSize, cropVolSize, initsub, shift, dropfile, memory)
% compute library by writing a bit at a time to file

    volclass = class(vol);
    volclassfn = str2func(volclass);
    
    nGridVoxels = numel(initsub{1});
    if nargin <= 6
        memRows = ceil(numel(vol) ./ prod(patchSize));
    else
        rowMemory = prod(patchSize) * 8;    
        memRows = max(floor(memory ./ rowMemory), 1);
    end

    
    % pre-allocation inside matlab file
    dropfile.lib(nGridVoxels, 1:prod(patchSize)) = volclassfn(0); 
    
    for i = 1:memRows:nGridVoxels
        range = i:min(i + memRows - 1, nGridVoxels);
        tmpsub = cellfunc(@(x) x(range), initsub);
        library = memlib(vol, patchSize, cropVolSize, tmpsub, shift);
        
        % todo specify cols?
        dropfile.lib(range, :) = library;
    end
end

function varargout = vol2libcell(vol, patchSize, varargin)

    % sep fcn
    varargout{1} = cell(size(vol));
    idx = cell(size(vol));
    sizes = cell(size(vol));
    gridSize = cell(size(vol));
    
    % run vol2lib on each patch
    for i = 1:numel(vol)
        [varargout{1}{i}, idx{i}, sizes{i}, gridSize{i}] = ...
            patchlib.vol2lib(vol{i}, patchSize, varargin{:});
    end
    
    if nargout >= 2, varargout{2} = idx; end
    if nargout >= 3, varargout{3} = sizes; end
    if nargout >= 4, varargout{4} = gridSize; end
    if nargout == 5,
        idxcell = cell(numel(vol), 1);
        for i = 1:numel(vol),
            idxcell{i} =  i*ones(size(varargout{1}{i}, 1), 1);
        end
        varargout{5} = idxcell;
    end
end        

function [patchOverlap, dofiledrop, dropfile, memory] = parseInputs(varargin)

    patchOverlap = {'sliding'};
    if isodd(nargin)
        patchOverlap = varargin(1);
        varargin = varargin(2:end);
    end
    
    p = inputParser();
    p.addParameter('savefile', '', @ischar);
    p.addParameter('memory', -1, @isscalar);
    p.parse(varargin{:});
    
    dofiledrop = ~isempty(p.Results.savefile);
    dropfile = [];
    if dofiledrop
         dropfile = matfile(p.Results.savefile, 'Writable', true);
    end
    
    memory = {};
    if p.Results.memory > 0
        memory = {p.Results.memory};
    end
    
end
