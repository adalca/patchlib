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
%   'sliding', 'discrete', or 'half'. see patchlib.overlapkind for details of the supported overlap
%   kinds. If not specified (i.e. function has only 2 inputs), default overlap is 'sliding'.
%
%   Note: vol2lib will cut the volume to fit the right number of patches.
%
%   lib = vol2lib(..., Param, Value, ...) allows for the following param/value specifications:
%   - 'savefile': filename.mat - allows for partial computations with parital save/load to the given
%       filename.mat. This is an ideal option for huge libraries that don't (or barely do) fit in
%       memory --- the function will work with matfile() to dynamically read or write parts of the
%       necessariy variables to disc. Instead of returning the library lib, vol2lib will return a
%       matfile pointer, libfile. At this point, typing libfile.lib will load the library into
%       memory. Since you probably had memory constraints, you may want to load the library in
%       parts, just as libfile.lib(1, :), etc.
%
%   - 'memory': specify the memory in bytes if using savefile (memory-based) mode. We recommend this
%       value to be no more than about a fifth of your current available memory. On PC, the default
%       is a tenth of the available physical memory. On other systems, no default is available.
%   
%   - 'procfun': a function to allow to process the (potentially partial) library in memory. This is
%       useful for when using file based library construction, and you only want, for example, to 
%       keep part of the library before writing it to file.
%
%   - 'verbose': true/false - verbosity.
%
%   - 'fulllib': force a library of the entire volume (i.e. do not crop the volume) - this means 
%       some of the patches might have NANs towards the end of the volume. 
%
%   - 'locations': specify particular desired patches by giving the location of the top-left corner
%       of the patches in the volumes. If this is specified, vol2lib will *only* return the specific
%       patches. This can be significantly faster than building the entire library if only specific
%       patches are desired. locations must be a [nDesiredPatches x nDims].
%
%   [..., idx, libVolSize, gridSize] = vol2lib(...) returns the index of the starting (top-left)
%   point of every patch in the *original* volume, and the size of the volumes size, which is
%   smaller than or equal to the size of vol. It will be smaller than the initial volume if the
%   volume had to be cropped. Also returns the number of patches gridSize.
%
%   [..., libIdx] = vol2lib(...) only given a cell of vols, returns a cell array with each entry
%   being a column vector with the same number of rows as library, indicating the volume index (i.e.
%   1..numel(vols))
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
    
    % input checking
    narginchk(2, inf);
    [patchOverlap, opt] = parseInputs(vol, patchSize, varargin{:});
    nDims = ndims(vol);
    volSize = size(vol);
    
    % if we force a full library construction, this is a slightly different execution
    if opt.fulllib
        varargout = cell(nargout, 1);
        [varargout{:}] = fulllib(vol, patchSize, varargin{:});
        return;
    end

    % see if we need to build the entire library or not
    manyLocations = size(opt.locations, 1) > (numel(vol) / 10) && prod(patchSize) < 1332;
    buildWholeLib = isempty(opt.locations) || manyLocations;
    if ~buildWholeLib
        [outlib, grididx] = vol2liblocations(vol, patchSize, opt.locations);
        gridSize = NaN;
        cropVolSize = size(vol);
        
    else
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
        if ~opt.dofiledrop
            library = memlib(vol, initsub, shift, opt.procfun);
            libsize = size(library);
            outlib = library;
            
        else
            assert(isempty(opt.locations), 'if locations are specified, cannot use filelib right now :(');
            filelib(vol, patchSize, initsub, shift, opt.dropfile, opt.procfun, opt.memory{:});
            opt.dropfile.grididx = grididx(:);
            opt.dropfile.cropVolSize = cropVolSize;
            opt.dropfile.gridSize = gridSize;
            libsize = size(opt.dropfile, 'lib');
            outlib = opt.dropfile;
        end
        
        if ~isempty(opt.locations)
            assert(all(patchOverlap == (patchSize + 1)));
            grididx = subvec2ind(gridSize, opt.locations);
            outlib = outlib(idxsamples, :);
            gridSize = NaN;
        end
    end
    
    if isempty(opt.locations)
        % check final library size
        assert(numel(grididx) == libsize(1), ...
            'Something went wrong with the library of index computation. Sizes don''t match.');
        assert(prod(gridSize) == libsize(1), ...
            'Something went wrong with the library of index computation. Sizes don''t match.');
    end
    
    % outputs 
    outputs = {outlib, grididx(:), cropVolSize, gridSize};
    varargout = outputs(1:nargout); 
end

function [patches, idx] = vol2liblocations(vol, patchSize, locs)
    idx = subvec2ind(size(vol), locs);
    nPatches = size(locs, 1);
    
    patches = zeros(nPatches, prod(patchSize));
    startc = mat2cell(locs, ones(size(locs, 1), 1), size(locs, 2));
    endc = mat2cell(bsxfun(@plus, locs, patchSize-1), ones(size(locs, 1), 1), size(locs, 2));
    
    for i = 1:nPatches
        rangec = arrayfunc(@(l, p) l:p, startc{i}, endc{i});
        v = vol(rangec{:});
        patches(i, :) = v(:)';
    end
end

function varargout = fulllib(vol, patchSize, varargin)
% force full library construction, including edge patches that might only be partially in the volume
% TODO: there might be a slightly more efficient way to do this using math. 
% see gridsize() with 

    % get logical vol
    logvol = true(size(vol));
    logvol = padarray(logvol, patchSize - 1, 'post');
    
    % get sub of large vol within logvol
    patchOverlap = parseInputs(varargin{:});
    idx = patchlib.grid(size(logvol), patchSize, patchOverlap{:}); 
    subvec = ind2subvec(size(logvol), idx(:));
    keeplog = logvol(idx(:));
    
    % compute new volume size
    newVolSize = max(subvec(keeplog, :), [], 1) + patchSize - 1;
    assert(all(newVolSize >= size(vol)));
    assert(all(newVolSize <= size(logvol)));
    
    % compute the minimal necessary logical volume
    logvol = cropVolume(logvol, ones(1, ndims(vol)), newVolSize);
    newvol = nan(size(logvol));
    newvol(logvol) = vol;
    
    % run vol2lib with a bigger volume
    f = find(strcmp('fulllib', varargin)); varargin{f+1} = false;
    varargout = cell(1, nargout);
    [varargout{:}] = patchlib.vol2lib(newvol, patchSize, varargin{:});
    
    % recompute  outputs
    assert(nargout <= 4);
    if nargout >= 2
        varargout{2} = ind2ind(newVolSize, size(vol), varargout{2});
    end
    if nargout >= 3
        assert(all(varargout{3} == newVolSize));
    end
end

function library = memlib(vol, initsub, shift, procfun)
% compute library in memory
%   vol - the volume
%   initsub - the initial (top left) location of each patch (nDims cell with each entry being the size of grididx)
%   shift - prod(patchSize) x nDims
%   procfun - a function to process the library, plib = procfun(lib)

    % use mex if needed. 
    % This will only be detected from withint vol2lib since it's currently
    % private to +patchlib
    useMex = numel(which('mexMemlib')) > 0;

    % Old Method
    if ~useMex
        % update subscript library
        shiftfn = @(x, y) bsxfun(@plus, x(:), y) - 1;
        sub = cellfunc(shiftfn, initsub, dimsplit(1, shift')');
        
        % compute the library of linear indexes into the volume
        idxvec = sub2indfast(size(vol), sub{:});
        clear sub;
        
        % compute final library
        library = vol(idxvec);
    
    % new mex method
    else
        islog = islogical(vol);
        if islog, vol = vol * 1; end
        assert(isfloat(vol), 'Currently, mex implementation only accepts class double');
        library = mexMemlib(vol, initsub, shift);
        if islog, library = logical(library); end
        
        % check outputs
    %         assert(all(library(:) == library2(:)))
    end
    
    library = procfun(library);
end


function filelib(vol, patchSize, initsub, shift, dropfile, procfun, memory)
% compute library by writing a bit at a time to file

    volclass = class(vol);
    volclassfn = str2func(volclass);
    
    nGridVoxels = numel(initsub{1});
    if nargin <= 7
        memRows = ceil(numel(vol) ./ prod(patchSize));
    else
        % w = whos('vol'); b = w.bytes ./ numel(vol);
        b = 4; % since using uint32 for the sub.
        rowMemory = prod(patchSize) * b;
        memRows = max(floor(memory ./ rowMemory), 1);
    end

    if memRows >= nGridVoxels
        % avoid the loop if can do all in memory
        dropfile.lib = memlib(vol, initsub, shift, procfun);
        
    else
        for i = 1:memRows:nGridVoxels
            range = i:min(i + memRows - 1, nGridVoxels);
            tmpsub = cellfunc(@(x) x(range), initsub);
            library = memlib(vol, tmpsub, shift, procfun);

            if i == 1
                % pre-allocation inside matlab file
                % dropfile.lib(nGridVoxels, 1:prod(patchSize)) = volclassfn(0);
                dropfile.lib(nGridVoxels, 1:size(library, 2)) = volclassfn(0);
            end

            % todo specify cols?
            dropfile.lib(range, 1:size(library, 2)) = library;
        end
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

function [patchOverlap, opt] = parseInputs(vol, patchSize, varargin)

    patchOverlap = {'sliding'};
    if isodd(numel(varargin))
        patchOverlap = varargin(1);
        varargin = varargin(2:end);
    end
    
    % default memory usage.
    defmem = -1;
    % TODO: unfortunately this is slow. memory() call is 0.1 seconds, which is a problem if doing
    % many calls.
    %     if ispc
    %         [~, sys] = memory();
    %         defmem = sys.PhysicalMemory.Available/3;
    %     end
    
    % parse rest of inputs
    p = inputParser();
    p.addParameter('savefile', '', @ischar);
    p.addParameter('memory', defmem, @isscalar);
    p.addParameter('verbose', false, @islogical);
    p.addParameter('fulllib', false, @islogical);
    p.addParameter('locations', [], @isnumeric);
    p.addParameter('procfun', @(x) x, @(x) isa(x, 'function_handle'));
    p.parse(varargin{:});
    
    % display memory message
    if p.Results.verbose
        fprintf('Default memory:%f, passed memory: %f\n', defmem, p.Results.memory);
    end
    
    opt.dofiledrop = ~isempty(p.Results.savefile);
    opt.dropfile = [];
    if opt.dofiledrop
         opt.dropfile = matfile(p.Results.savefile, 'Writable', true);
         assert(p.Results.memory > 0, 'Need positive memory value. Detected: %f', p.Results.memory);
    end
    
    opt.mem = {};
    if p.Results.memory > 0
        opt.mem = {p.Results.memory};
    end
    
    opt.procfun = p.Results.procfun;
    opt.fulllib = p.Results.fulllib;
    opt.locations = p.Results.locations;
    
    msg = 'All specified locations must be within the volume minus patchSize';
    assert(all(all(bsxfun(@lt, opt.locations, size(vol) - patchSize + 2))), msg);
    
    msg = 'Given Locations, patchOverlap should be sliding or not specified.';
    if ischar(patchOverlap{1})
        assert(strcmp(patchOverlap{1}, 'sliding'), msg);
    else
        assert(all(patchOverlap{:} == (patchSize - 1)), msg);
    end
end
