function [sub, loc, corresp] = corresp2disp(siz, varargin)
% CORRESP2DISP transform reference locations to displacement.
%   sub = corresp2disp(srcsiz, insub) with insub as nDim cell, with each entry being a Nx1 vector
%       with N = prod(srcsiz), or a srcsiz vector, indicating for each source voxel, where the
%       correspondance is into the reference. 
%   
%   sub = corresp2disp(srcsiz, refsiz, pIdx) reference idx has to be NxM where N = prod(srcsiz), M 
%       can be anything >= 1. sub is then a cell array with entries NxM
%
%   sub = corresp2disp(srcsiz, refsiz, pIdx, rIdx) 
%
%   sub = corresp2disp(..., 'reshape') reshape each sub vector to siz
%
%   [sub, loc, corresp] = corresp2disp(...)
%
%
% Example:
%   refSize = [100, 100];
%   srcSize = [3, 3];
%   nSrc = prod(srcSize);
%   insub = {randi([1, refSize(1)], [nSrc, 1]), randi([1, refSize(1)], [nSrc, 1])};
%   inidx = sub2ind(refSize, insub{:});
%   sub1 = patchlib.corresp2disp(srcSize, refSize, sub2ind(refSize, inidx));
%   sub2 = patchlib.corresp2disp(srcSize, insub);
%   % visualize
%   patchview.figure; 
%   subplot(1,2,1); imagesc(reshape(insub{1}, srcSize)); 
%   subplot(1,2,2); imagesc(reshape(sub1{1}, srcSize));
%
% TODO: warning: is this dealing with non-full overlaps properly? Not Sure. 
    
    doreshape = strcmp('reshape', varargin{end});
    if doreshape
        varargin = varargin(1:end-1);
    end

    loc = size2ndgrid(siz);
    loc = cellfun(@(x) x(:), loc, 'UniformOutput', false);
    
    % 
    if numel(varargin) == 2 || numel(varargin) == 3
        % get the reference sizes, 
        refsize = varargin{1};
        if ~iscell(refsize), 
            refsize = {refsize}; 
        end
        pIdx = varargin{2};
        rIdx = ifelse(numel(varargin) == 2, 'ones(size(pIdx))', 'varargin{3}', true);
        
        corresp = cellfun(@(x) zeros(size(pIdx)), cell(1, numel(siz)), 'UniformOutput', false);
        
        for i = 1:numel(refsize)
            rMap = rIdx == i;
            correspm = cell(1, numel(refsize{i}));
            [correspm{:}] = ind2sub(refsize{i}, pIdx(rMap));
            
            for d = 1:numel(refsize{1})
                corresp{d}(rMap) = correspm{d};
            end
        end
    else
        
        assert(numel(varargin) == 1);
        corresp = varargin{1};
    end
        
    sub = cellfun(@join, corresp, loc, 'UniformOutput', false);
    
    if doreshape 
        sub = cellfun(@(x) reshape(x, siz), sub, 'UniformOutput', false);
        corresp = cellfun(@(x) reshape(x, siz), corresp, 'UniformOutput', false);
        loc = cellfun(@(x) reshape(x, siz), loc, 'UniformOutput', false);
    end
end

function j = join(x, y)
    assert(size(x, 1) == size(y, 1));
    j = bsxfun(@minus, x, y);
end
