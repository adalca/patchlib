function sub = corresp2disp(siz, varargin)
% CORRESP2DISP transform locations to displacement.
%   sub = corresp2disp(srcsiz, insub) with insub as nDim cell, with each entry being a Nx1 vector
%       with N = prod(srcsiz), or a srcsiz vector, indicating for each source voxel, where the
%       correspondance is into the reference. 
%   
%   sub = corresp2disp(srcsiz, refsiz, idx) idx has to be NxM where N = prod(srcsiz), M can be
%       anything >= 1. sub is then a cell array with entries NxM
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
    
    loc = size2ndgrid(siz);
    loc = cellfun(@(x) x(:), loc, 'UniformOutput', false);
    
    if nargin == 3
        refsize = varargin{1};
        idx = varargin{2};
        corresp = cell(1, numel(refsize));
        [corresp{:}] = ind2sub(refsize, idx);
    else
        assert(nargin == 2);
        corresp = varargin{1};
    end
    
    sub = cellfun(@join, corresp, loc, 'UniformOutput', false);
end

function j = join(x, y)
    assert(size(x, 1) == size(y, 1));
    j = bsxfun(@minus, x, y);
end
