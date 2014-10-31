function colmap = corresp2D(pIdx, refgridsize, srcgridsize, varargin)
% Warning: this function needs to be improved dramatically... or dropped...
%   Maybe just functionality for the quiver...
%   Idea: quiver different color for different references....
%
% right now we force 2D, but we tried to make most of the code to be dimension independent. 
%
% [patches, pDst, pIdx, pRefIdxs, srcgridsize, refgridsize] = patchlib.volknnsearch(rand(12, 8), {rand(10, 10), rand(10, 10)}, [5, 5]);
% patchview.corresp2D(pIdx, refgridsize, srcgridsize, 'refIndex', pRefIdxs);

    [h, mode, vol, rIdx] = parseInputs(numel(pIdx), varargin{:});
    if ~iscell(refgridsize), refgridsize = {refgridsize}; end
    nDims = numel(srcgridsize);
    uRefs = unique(rIdx); % need to index in uRefs then!!
    colmap = jitter(numel(uRefs)); % TODO not do this for one ref only.
    assert(nDims == 2);
    assert(size(pIdx, 2) == 1);
    
    % open the figure;
    figure(h);
    
    % get the reference correspondance volumes
    corresp = zeros(size(pIdx, 1), nDims);
    for i = 1:numel(uRefs)
        rMap = rIdx == uRefs(i);
        corresp(rMap, :) = ind2subvec(refgridsize{i}, pIdx(rMap));
    end
    
    correspvols = cell(1, nDims);
    for d = 1:nDims
        correspvols{d} = reshape(corresp(:, d), srcgridsize);
    end
    rIdx = reshape(rIdx, srcgridsize);
    
    % get the current location
    curloc = cell(1, nDims);
    range = getNdRange(srcgridsize);
    [curloc{:}] = ndgrid(range{:});
    
    % compute the displacements (reference correspondance minus current location)
    diffs = cellfun(@minus, correspvols, curloc, 'UniformOutput', false);
    
    % display
    switch mode
        case 'quiver'
            if nDims == 2
                if ~isempty(vol), imagesc(vol); end
                hold on;
                [xi, yi] = curloc{:};
                [xd, yd] = diffs{:};
                for c = 1:numel(uRefs)
                    p = rIdx == uRefs(c);
                    quiver(xi(p), yi(p), xd(p), yd(p), 'Color', colmap(c, :), 'AutoScale','off');
                end
            else
                assert(nDims == 3);
                quiver3(curloc{:}, diffs{:}, 'AutoScale','off');
            end
        
        case 'separate'
            maxval = max(cellfun(@(x) max(x(:)), diffs));
            minval = min(cellfun(@(x) min(x(:)), diffs));
            for i = 1:nDims
                subplot(1, nDims, i);
                imagesc(diffs{i});
                title(sprintf('Dimension %i displacement', i));
                axis equal off;
                colormap gray;
                hold on;
                
                % slow: scatter(curloc{1}(:), curloc{2}(:), 30, colmap(rIdx, :), 'o');
                for c = 1:numel(uRefs)
                    p = rIdx == uRefs(c);
                    plot(curloc{2}(p), curloc{1}(p), '.', 'Color', colmap(c, :));
                end
                caxis([minval, maxval]);
            end
            
        case 'overlap'
            vol = zeros([size(diffs{1}) 3]);
            for i = 1:nDims
                vol(:, :, i) = diffs{i};
            end
            vol = vol - min(vol(:));
            vol = vol ./ max(vol(:));
            imagesc(vol);
    end
    
end

function [h, mode, vol, rIdx] = parseInputs(nPatches, varargin)

    p = inputParser();
    p.addParameter('mode', 'separate', @(x) ischar(validatestring(x, {'quiver', 'separate', 'overlap'})));
    p.addParameter('vol', []);
    p.addParameter('refIndex', []);
    p.addParameter('h', []);
    p.parse(varargin{:});
    
    h = p.Results.h;
    if isempty(h)
        h = patchview.figure();
    end
    
    mode = p.Results.mode;
    vol = p.Results.vol;
    
    
    rIdx = p.Results.refIndex;
    if isempty(rIdx)
        rIdx = ones(nPatches, 1);
    end
    
    % TODO: dimentional checks
    % quicker - 2d, 3d
    % separate - ok any dim? in theory yes, but showing 1 slice??
    % overlap - ok up to 3D
    
end

