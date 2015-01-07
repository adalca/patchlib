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
%   sub = corresp2disp(..., 'reshape', logical) reshape each sub vector to siz
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
    warning('for now, refgrididx is assumed to be ''sliding''');

    f = find(cellfun(@ischar, varargin), 1);
    doreshape = false;
    srcgrididx = reshape(1:prod(siz), siz);
    if numel(f) == 1
        v = varargin(f:end);
        varargin = varargin(1:(f-1));
        p = inputParser();
        p.addParameter('reshape', doreshape, @islogical);
        p.addParameter('srcGridIdx', srcgrididx, @isnumeric);
        p.parse(v{:});
        doreshape = p.Results.reshape;
        srcgrididx = p.Results.srcGridIdx;
    end
        
    
    
    
    subvec = ind2subvec(siz, srcgrididx(:));
    loc = num2cell(subvec, [1, numel(siz)]);
%     loc = size2ndgrid(siz);
%     loc = cellfun(@(x) x(:), loc, 'UniformOutput', false);
    
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
        
        assert(numel(refsize) >= max(rIdx(:)), 'not enough reference sizes have been passed');
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
        %assumes srcgrididx is in the sight format
        resiz = size(srcgrididx);
        sub = cellfun(@(x) reshape(x, resiz), sub, 'UniformOutput', false);
        corresp = cellfun(@(x) reshape(x, resiz), corresp, 'UniformOutput', false);
        loc = cellfun(@(x) reshape(x, resiz), loc, 'UniformOutput', false);
    end
end

function j = join(x, y)
    assert(size(x, 1) == size(y, 1));
    j = bsxfun(@minus, x, y);
end
