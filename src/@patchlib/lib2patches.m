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
    [patchSize, docell] = parseinputs(size(lib{1}, 2), varargin{:});
    K = size(pIdx, 2);
    
    % initiate patches
    tmppatches = zeros([numel(pIdx), size(lib{1}, 2)]);
    for i = 1:numel(lib)
        libmap = lIdx(:) == i;
        tmppatches(libmap, :) = lib{i}(pIdx(libmap), :);
    end
    
    % reshape to [M x K x V]
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

function [patchSize, docell] = parseinputs(V, varargin)
    narginchk(1, 3)
    
    if nargin == 1
        patchSize = patchlib.guessPatchSize(V);
    end
    docell = '';
    
    if numel(varargin) >=1
        if isnumeric(varargin{1})
            patchSize = varargin{1};
        else
            docell = varargin{1};
            patchSize = patchlib.guessPatchSize(V);
        end
    end
       
    if nargin == 3
        docell = varargin{2};
    end    
end
    
    
