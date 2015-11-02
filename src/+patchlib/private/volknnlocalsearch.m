function [pIdx, pRefIdxs, pDst] = volknnlocalsearch(src, refs, spacing, fillK, varargin)
% volknnlocalsearch. private function for volknnsearch.
% perform a local search, with <spacing> around each voxel in each ref included in the search for
% knn for that voxel.
%   
%   src has fields: vol, grididx, lib, mask
%   refs has fields: vol, grididx, gridsize, lib

    nRefs = numel(refs);
    
    % get subscripts refs.subs that match the linear index in refs
    fn = @(x, y) ind2subvec(size(x), y(:));
    refsubs = cellfunc(fn, {refs(:).vol}', {refs(:).grididx}');
    [refs.subs] = refsubs{:};
    assert(size(refs(1).subs, 1) == numel(refs(1).grididx));
    
    % get the linear indexes grididx from full volume space to gridSize
    % problem: gridSize ir misleading since it doesn't start at [1,1,1]. 
    fn = @(x, s) subvec2ind(x, bsxfun(@minus, s + 1, s(1, :)));
    ridx = cellfunc(fn, {refs(:).gridSize}', refsubs); 

    % get subscript local ranges for each voxel. 
    % Pre-computation should save time inside the main for-loop
    srcgridsub = ind2subvec(size(src.vol), src.grididx(:));
    mingridsub = max(bsxfun(@minus, srcgridsub, spacing), 1);
    fn = @(x) bsxfun(@min, bsxfun(@plus, srcgridsub, spacing), x(end, :));
    maxgridsub = cellfunc(fn, {refs.subs});
    
    % get input K
    fK = find(strcmp('K', varargin), 1, 'first');
    K = ifelse(isempty(fK), '1', 'varargin{fK + 1}', true);
        
    % go through each voxel, get reference patches from nearby from each reference.
    pIdx = nan(size(src.lib, 1), K);
    pRefIdxs = nan(size(src.lib, 1), K);
    pDst = nan(size(src.lib, 1), K);
    
    % if there is a user specified distance, do local refine.
    % otherwise, globalrefine is actually probably faster due to the mex implementation.
    % TODO - move this to options...
    f = find(strcmp('Distance', varargin));
    DO_LOCAL = numel(f) > 0 && ~ischar(varargin{f+1});
        
    try
        if ~DO_LOCAL % first computes *all* the distances.
            % compute all of the pairwise distances
            tmp_dst = pdist2withParamValue(src, refs, varargin{:});
        end
    catch err
        fprintf(2, err.message);
        DO_LOCAL = true;
    end
        
    subset = find(src.mask(src.grididx))';
    for i = subset(:)' %1:size(src.lib, 1)
        
        % get the location linear index and reference index for the windows around voxel i.
        [gidxsall, riall, wIdx] = winRefIdx(refs, ridx, mingridsub, maxgridsub, i);
        if fillK % fill K if necessary.
            pIdx(i, :) = 1;
            pDst(i, :) = inf;
            pRefIdxs(i, :) = 1;
        else
            assert(size(gidxsall, 1) >= K, ...
                'Spacing does not allow %d nearest neighbours (%d)', K, size(gidxsall, 1));
        end
        
        if DO_LOCAL
            % extract the relevant patches from the references.
            ipatches = arrayfunc(@(r) refs(r).lib(wIdx{r}, :), 1:nRefs);
            ipatchesall = cat(1, ipatches{:});

            % do a nearest neighbor search among the patches extract from the window
            [p, d] = knnsearch(ipatchesall, src.lib(i, :), varargin{:});
            
        else
            % get an overall index into the (loc-in-reference, ref-nr) ordering used
            tmp_gidxsall = varsub2ind(cellfun(@(x) size(x, 1), {refs.lib}), gidxsall, riall);
            
            % for location i, sort the pre-computed distances and take out the first K components
            [tmp_d2, tmp_di] = sort(tmp_dst(i, tmp_gidxsall), 'ascend');
            p = tmp_di(1:min(K, numel(tmp_di)));
            d = tmp_d2(1:min(K, numel(tmp_d2)));
        end
        
        % note we don't use 1:K, instead we use 1:numel(p) since we might allow less than K matches
        pIdx(i, 1:numel(p)) = gidxsall(p);
        pDst(i, 1:numel(p)) = d;
        pRefIdxs(i, 1:numel(p)) = riall(p);
    end
    assert(~any(isnan(pDst(:)))); % cannot use isclean since inf is fine.
end

function dst = pdist2withParamValue(src, refs, varargin)
% get all the tmp_d. This is equivalent to 
% >> tmp_d = pdist2(src.lib, cat(1, refs.lib), varargin{:}); or
% >> tmp_d = pdist2mex(src.lib',cat(1, refs.lib{:})','euc',[],[],[]);
% but allows for specifying knnsearch param/value pairs in varargin, which we want to keep.
    
    % erase K from varargin
    fK = find(strcmp('K', varargin), 1, 'first');
    if numel(fK) == 1
        varargin(fK:fK+1) = [];
    end
    [idx, dst] = knnsearch(cat(1, refs.lib), src.lib, 'K', inf, varargin{:});

    [~, si] = sort(idx, 2, 'ascend');
    for i = 1:size(dst, 1), 
        dst(i, :) = dst(i, si(i, :)); 
    end
end

function [gidxsall, riall, wIdx, refIdx] = winRefIdx(refs, ridx, mingridsub, maxgridsub, i)
% get the location linear index and reference index for the windows around point i.

    % extract the number of references
    nRefs = numel(refs);

    wIdx = cell(nRefs, 1);
    for r = 1:nRefs
        % get all the subs used in this reference.
        locsub = refs(r).subs;
        
        % get the indexes of within a window of i
        % these will be mingridsub_i <= locsub <= maxgridsub{r}_i
        wIdxsel = bsxfun(@ge, locsub, mingridsub(i, :)) & bsxfun(@le, locsub, maxgridsub{r}(i, :));
        wIdxsel = all(wIdxsel, 2);
        
        % put all the neighbor indexes into a cell
        wIdx{r} = ridx{r}(wIdxsel(:));
    end
    
    % combine all of the window indexes and reference indexes
    gidxsall = cat(1, wIdx{:});
    
    % also set up a reference index vector to match
    refIdx = arrayfunc(@(r) r*ones(size(wIdx{r})), 1:nRefs);
    riall = cat(1, refIdx{:});
end
