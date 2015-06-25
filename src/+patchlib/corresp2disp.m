function [disp, locsub, correspsub] = corresp2disp(siz, varargin)
% CORRESP2DISP transform reference locations to relative displacement.
%   disp = corresp2disp(srcsiz, insub) with insub as nDim cell, with each entry being a Nx1 vector
%       with N = prod(srcsiz), or a srcsiz vector, indicating for each source voxel, where the
%       correspondance is into the reference. 
%   
%   disp = corresp2disp(srcsiz, refsiz, pIdx) reference idx has to be NxM where N = prod(srcsiz), M 
%       can be anything >= 1. sub is then a cell array with entries NxM
%
%   disp = corresp2disp(srcsiz, refsiz, pIdx, rIdx) 
%
%   disp = corresp2disp(..., Param/Value)
%       'reshape': logical reshape each sub vector to siz
%       'srcGridIdx': index or source, assumes sliding grid index otherwise
%       'refGridIdx': index or reference, assumes sliding grid index otherwise for each reference
%
%   [sub, locsub, correspsub] = corresp2disp(...)
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
% See also: interpDisp, corresp2sub
%
% TODO: warning: is this dealing with non-full overlaps properly? Not Sure. 

    % parse inputs
    [doreshape, srcgrididx, refargs] = parseInputs(siz, varargin{:});
    
    % get subscript of the locations of the current source grid
    % loc will be a nDims x 1 cell array
    locsub = dimsplit(2, ind2subvec(siz, srcgrididx(:)));
    
    % get subscript of correspondances
    if numel(refargs) == 1
        correspsub = refargs{1};
    else
        correspsub = patchlib.corresp2sub(refargs{:});
    end
        
    % 'join' correp with loc (mainly does @minus, with an assert);
    disp = cellfunc(@join, correspsub, locsub);
    
    % if asked to reshape, reshape to be in the size of the original volume
    if doreshape 
        % assumes srcgrididx is in the sight format
        resiz = size(srcgrididx);
        disp = cellfunc(@(x) reshape(x, resiz), disp);
        correspsub = cellfunc(@(x) reshape(x, resiz), correspsub);
        locsub = cellfunc(@(x) reshape(x, resiz), locsub);
    end
end

function j = join(x, y)
% 'join' correp with loc (mainly does @minus, with an assert);
    assert(size(x, 1) == size(y, 1), 'join sizes are different: %d, %d', size(x, 1), size(y, 1));
    j = bsxfun(@minus, x, y);
end

function [doreshape, srcgrididx, refargs] = parseInputs(siz, varargin)
% check inputs
% TODO: maybe? move input handling from corresp2sub here? 
% But might be better to move corresp2sub out of here.

    doreshape = false;
    srcgrididx = reshape(1:prod(siz), siz);
    
    % find the first char input
    f = find(cellfun(@ischar, varargin), 1);
    if numel(f) == 1
        % assuming args after first char are param/value pairs. 
        % TODO: could do this with addOptional in inputParse more cleanly?
        refargs = varargin(1:(f-1)); 
        assert(any(numel(refargs) == [1, 2, 3])); % should have 1, 2 or 3 ref-related args
        
        % Param/Value arguments
        pvargs = varargin(f:end);
        p = inputParser();
        p.addParameter('reshape', doreshape, @islogical);
        p.addParameter('srcGridIdx', srcgrididx, @isnumeric);
        p.addParameter('refGridIdx', -1, @isnumeric);
        p.parse(pvargs{:});
        doreshape = p.Results.reshape;
        srcgrididx = p.Results.srcGridIdx;
        
        % add refgrididx if necessary
        if ~(isscalar(p.Results.refGridIdx) && p.Results.refGridIdx == -1)
            assert(numel(refargs) > 1, 'Specify refsize, pIdx, <rIdx> if you set refGridIdx');
            if numel(refargs) == 2
                refargs{end+1} = refargs(pIdx*0+1);
            end
            refargs{end+1} = p.Results.refGridIdx;
        end
    end
end
