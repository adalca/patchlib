function [pIdx, pRefIdxs, pDst] = volknnlocalsearch(src, refs, spacing, varargin)
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
    subset = find(src.mask(src.grididx))';
    
    % if there is a user specified distance, do local refine.
    % otherwise, globalrefine is actually probably faster due to the mex implementation.
    f = find(strcmp('Distance', varargin));
    if numel(f) > 0 && ~ischar(varargin{f+1})
        method = 'localrefine'; 
    else
        method = 'globalrefine';
    end
    
    switch method
        case 'localrefine'
            for i = subset(:)' %1:size(src.lib, 1)
                
                % compute the reference linear idx and reference number for the regions around this
                % voxel
                ridxwindow = cell(nRefs, 1);
                ipatches = cell(nRefs, 1);
                refIdx = cell(nRefs, 1);
                for r = 1:nRefs
                    idxsel = bsxfun(@ge, refs(r).subs, mingridsub(i, :)) & ...
                        bsxfun(@le, refs(r).subs, maxgridsub{r}(i, :));
                    ridxwindow{r} = ridx{r}(all(idxsel, 2));
                    ridxwindow{r} = ridxwindow{r}(:);    

                    rlib = refs(r).lib;
                    ipatches{r} = rlib(ridxwindow{r}, :);
                    refIdx{r} = r * ones(size(ridxwindow{r}));
                end
                gidxsall = cat(1, ridxwindow{:});    
                ipatchesall = cat(1, ipatches{:});
                riall = cat(1, refIdx{:});
                assert(size(gidxsall, 1) >= K, 'Spacing does not allow %d nearest neighbours', K);

                [p, d] = knnsearch(ipatchesall, src.lib(i, :), varargin{:});

                pIdx(i, :) = gidxsall(p);
                pDst(i, :) = d; 
                pRefIdxs(i, :) = riall(p);
            end
            
        case 'globalrefine' % first computes *all* the distances.
            
            % erase K from varargin
            if numel(fK) == 1
                varargin(fK:fK+1) = [];
            end
            
            % get all the tmp_d. This is requivalent to 
            % >> tmp_d = pdist2(src.lib, cat(1, refs.lib), varargin{:}); or
            % >> tmp_d = pdist2mex(src.lib',cat(1, refs.lib{:})','euc',[],[],[]);
            % but allows for specifying knnsearch param/value pairs in varargin
            [tmp_idx, tmp_d] = knnsearch(cat(1, refs.lib), src.lib, 'K', inf, varargin{:});
            
            [~, si] = sort(tmp_idx, 2, 'ascend');
            for i = 1:size(tmp_d, 1), tmp_d(i, :) = tmp_d(i, si(i, :)); end
            
            % go through each local search.
            for i = subset(:)'
                
                % compute the reference linear idx and reference number for the regions around this
                % voxel
                ridxwindow = cell(nRefs, 1);
                refIdx = cell(nRefs, 1);
                for r = 1:nRefs
                    idxsel = bsxfun(@ge, refs(r).subs, mingridsub(i, :)) & ...
                        bsxfun(@le, refs(r).subs, maxgridsub{r}(i, :));
                    ridxwindow{r} = ridx{r}(all(idxsel, 2));
                    ridxwindow{r} = ridxwindow{r}(:);
                    refIdx{r} = r * ones(size(ridxwindow{r}));
                end
                gidxsall = cat(1, ridxwindow{:});
                riall = cat(1, refIdx{:});
                assert(size(gidxsall, 1) >= K, ...
                    'Spacing does not allow %d nearest neighbours (%d)', K, size(gidxsall, 1));
                
                tmp_gidxsall = pr2idx(gidxsall, riall, cellfun(@(x) size(x, 1), {refs.lib}));
                [tmp_d2, tmp_di] = sort(tmp_d(i, tmp_gidxsall), 'ascend');
                pIdx(i, :) = gidxsall(tmp_di(1:K))';
                pDst(i, :) = tmp_d2(1:K);
                pRefIdxs(i, :) = riall(tmp_di(1:K))';
            end
            
        otherwise
            error('Internal method not found. Blame Adrian');
    end
   
end

function idx = pr2idx(pIdx, rIdx, refSizes)
    idx = pIdx * 0;
    for i = 1:numel(refSizes)
        idx(rIdx == i) = pIdx(rIdx == i) + sum(refSizes(1:i-1));
    end 
end

