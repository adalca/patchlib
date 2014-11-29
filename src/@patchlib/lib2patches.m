function patches = lib2patches(lib, pIdx, varargin)
% draft
%   lib2patches(lib, pIdx)
%   lib2patches(lib, pIdx, patchSize)
%   lib2patches(lib, pIdx, 'cell')
%   lib2patches(lib, pIdx, patchSize, 'cell')
%
% with a cell of libs clibs:
%   lib2patches(clib, pIdx, lIdx, ...)
%
%
%   lib - N x V
%   pIdx - M x K
%   patches - M x V x K or cell of {M x K} patchSize patches.

    % if cell library 
    if iscell(lib)
        narginchk(3, inf);
        lIdx = varargin{1};
        varargin = varargin(2:end);
    else
        lib = {lib};
        lIdx = ones(size(pIdx));
    end
    assert(all(size(pIdx) == size(lIdx)) && max(lIdx(:)) <= numel(lib));

    % check inputs
    [patchSize, docell, libfn] = parseinputs(size(lib{1}, 2), varargin{:});
    assert(isvector(patchSize));
    K = size(pIdx, 2);
    
    % create the patches
    tmppatches = zeros([numel(pIdx), prod(patchSize)]);
    for i = 1:numel(lib)
        i
        tlib = lib{i};
        if ~isempty(libfn)
            tlib = libfn(tlib, patchSize);
            assert(size(tlib, 2) == prod(patchSize), ...
                'library size %d does not match patch voxels %d', size(tlib, 2), prod(patchSize));
        end
        
        libmap = lIdx(:) == i;
        assert(isempty(max(pIdx(libmap))) || max(pIdx(libmap)) <= size(tlib, 1), ...
            'pIdx points to more than the available library');
        tmppatches(libmap, :) = tlib(pIdx(libmap), :);
    end
    
    % reshape tmppatches to [M x K x V]
    tmppatches = reshape(tmppatches, [size(pIdx), prod(patchSize)]);

    if strcmp(docell, 'cell')
        tmppatches = reshape(tmppatches, [size(pIdx), patchSize]);
        tmppatches = permute(tmppatches, [3:numel(patchSize) + 2, 1, 2]);
        p = num2cell(patchSize);
        if K == 1
            s = {ones(1, size(pIdx, 1))};
        else
            s = {ones(1, size(pIdx, 1)), ones(1, K)};
        end
        patches = squeeze(mat2cell(tmppatches, p{:}, s{:}));
    else
        % reshape to [M x V x K]
        patches = permute(tmppatches, [1, 3, 2]);    
    end     
end

function [patchSize, docell, libfn] = parseinputs(V, varargin)
% varargin can be:
%       [], patchSize, 'cell', libfn - in that order, but all are optional

    narginchk(1, 4)
    
    docell = '';
    libfn = [];
    
    if ~isempty(varargin) && isnumeric(varargin{1})
        patchSize = varargin{1};
        varargin = varargin(2:end);
    else
        patchSize = patchlib.guessPatchSize(V);
    end
    
    if ~isempty(varargin) && ischar(varargin{1})
        docell = varargin{1};
        varargin = varargin(2:end);
    end
    
    if ~isempty(varargin) 
        assert(isa(varargin{1}, 'function_handle'));
        libfn = varargin{1};
    end
end
