function patchRef2D(vol, refs, vIdx, pIdx, rIdx, patchSize, varargin)
% draft comments.
% See the location of the patches from the current volume in the reference volume(s)
    
    % setup
    [refs, volGrid, refGrids, refEquivs] = parseinputs(vol, refs, vIdx, pIdx, rIdx, patchSize, varargin{:});
    nRows = ifelse(isempty(refEquivs), 1, 2);
    nRefs = numel(refs);
    nPatches = size(vIdx, 1);
    
    % show figure
    patchview.figure();
    
    % show image
    subplot(nRows, nRefs+1, 1);
    imshow(vol);
    for i = 1:nRefs
        subplot(nRows, nRefs + 1, i + 1);
        imshow(refs{i});
    end
    
    % show patches
    color = jitter(nPatches);    
    for i = 1:nPatches
        subplot(nRows, nRefs+1, 1);
        patchview.drawPatchRect(volGrid(vIdx(i), :), patchSize, color(i, :));
        
        subplot(nRows, nRefs + 1, rIdx(i) + 1);
        patchview.drawPatchRect(refGrids{rIdx(i)}(pIdx(i), :), patchSize, color(i, :));
    end

end

function [refs, volGrid, refGrids, refEquivs] = parseinputs(vol, refs, vIdx, pIdx, rIdx, patchSize, varargin)
    
    assert(~isempty(patchSize));
    if ~iscell(refs)
        refs = {refs};
    end

    % get grids. 
    p = inputParser();
    p.addParameter('volPatchOverlap', 'sliding', @(x) ischar(x) || isnumeric(x));
    p.addParameter('refPatchOverlap', 'sliding', @(x) ischar(x) || isnumeric(x));
    p.addParameter('refEquivs', {});
    p.parse(varargin{:});
    inputs = p.Results;
    
    % get the volume grid
    gridC = patchlib.grid(size(vol), patchSize, inputs.volPatchOverlap);
    volGrid = ind2subvec(size(vol), gridC(:));
    if ~iscell(inputs.refPatchOverlap)
        inputs.refPatchOverlap = repmat({inputs.refPatchOverlap}, [numel(refs), 1]);
    end
    
    % prepare the reference grids
    assert(numel(refs) == numel(inputs.refPatchOverlap));
    refGrids = cell(numel(refs), 1);
    for i = 1:numel(refs)
        gridC = patchlib.grid(size(refs{i}), patchSize, inputs.refPatchOverlap{i});
        refGrids{i} = ind2subvec(size(refs{i}), gridC(:));
    end
    
    refEquivs = inputs.refEquivs;
    
    % some more checking.
    assert(size(pIdx, 1) == size(vIdx, 1));
    assert(size(pIdx, 1) <= size(volGrid, 1));
    assert(size(rIdx, 1) <= size(volGrid, 1));
end
