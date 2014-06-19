function example_viewPatchMatches2D()

    % prepare some parameters
    patchSize = [5, 5];
    nMatches = 5;
    nReps = 3;
    
    % simulate
    [origPatch, matches, seg] = simgroup(patchSize, nMatches);
    
    % test simple original and matches
    patchview.patchMatches2D(origPatch, matches);
    
    % test simple original and matches, with a different intensity scale, and segmentations
    patchview.patchMatches2D(origPatch*100, matches*100, seg, 'caxis', {[0 100], [0, 100], [0, 1]});
    
    % test original, matches, label equivalent and a second label 
    patchview.patchMatches2D(origPatch, matches, seg, seg .* (rand(size(seg)) < 0.5));

    % test several original patches with matching groups and segmentations
    origPatches = zeros(nReps, prod(patchSize));
    matchescell = cell(nReps, 1);
    segcell = cell(nReps, 1);
    for r = 1:nReps
        [origPatches(r, :), matchescell{r}, segcell{r}] = simgroup(patchSize, nMatches);
    end
    patchview.patchMatches2D(origPatches, matchescell, segcell);
    
end


function [origPatch, matches, seg] = simgroup(patchSize, nMatches)

    nVoxels = prod(patchSize);

    origPatch = rand([1, nVoxels]);
    matches = zeros(nMatches, nVoxels);
    for i = 1:nMatches
        matches(i, :) = origPatch(:)' + normrnd(0, 0.1, [1, nVoxels]);
    end
    
    % seg
    seg = zeros(nMatches, nVoxels);
    for i = 1:nMatches
        seg(i, :) = matches(i, :) < 0.5;
    end
end
