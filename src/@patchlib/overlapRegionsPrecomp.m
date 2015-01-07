function precomp = overlapRegionsPrecomp(patchSize, patchOverlap)

    signs = cellfunc(@(x) x(:), ndgrid2cell(repmat({-1:1}, [1, numel(patchSize)])));
    signs = cat(2, signs{:});
    
    volSize = ones(1, numel(patchSize))*3;
    idx = subvec2ind(volSize, signs + 2);
    assert(all(idx(:)' == 1:prod(volSize)));
    
    cvolSize = num2cell(volSize);
    precomp(cvolSize{:}) = struct();
    for i = idx(:)'
        [precomp(i).curIdx, precomp(i).neighborIdx] = ...
            patchlib.overlapRegions(patchSize, patchOverlap, signs(i, :));
    end
