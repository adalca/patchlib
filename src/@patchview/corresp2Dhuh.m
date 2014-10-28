function corresp2Dhuh(pIdx, refgridsize, refsize, srcgridsize, varargin)
% Warning: this function needs to be improved dramatically... or dropped...
%   Maybe just functionality for the quiver...
%   Idea: quiver different color for different references....

    [vols, titles, overlap, separate] = parseInputs(varargin{:});
    nRows = 1;
    nCols = numel(vols);
    if separate
        nCols = nCols + 3;
    end

    patchview.figure(); 
    colormap gray;
    
    if separate || numel(overlap) > 0
        idx = ind2ind(refgridsize, refsize, pIdx);
        [x, y] = ind2sub(refgridsize, pIdx);
        x = reshape(x, srcgridsize);
        y = reshape(y, srcgridsize);
        [xi, yi] = ndgrid(1:srcgridsize(1), 1:srcgridsize(2));
    end
    
    for i = 1:numel(vols)
        subplot(nRows, nCols, i); 
        imagesc(vols{i}); 
        title(titles{i}); 
        caxis([0, 1]);
        
        if ismember(i, overlap)
            hold on;
            quiver(xi, yi, x - xi, y - yi, 'AutoScale','off');
        end
        axis equal off;
    end

    if separate
        subplot(nRows, nCols, numel(vols) + 1); 
        imagesc(reshape(idx, srcgridsize)); 
        title('index');
        axis equal off;

        subplot(nRows, nCols, numel(vols) + 2);
        imagesc(x - xi);     
        axis equal off;
        title('x displacement');
        

        subplot(nRows, nCols, numel(vols) + 3);
        imagesc(y - yi);
        title('y displacement');
        axis equal off;
    end
    
end

function [vols, titles, overlap, separate] = parseInputs(varargin)

    p = inputParser();
    p.addParameter('overlap', [], @isnumeric);
    p.addParameter('separate', true, @islogical);
    p.addParameter('vols', {}, @iscell);
    p.addParameter('titles', {}, @iscellstr);
    p.parse(varargin{:});

    vols = p.Results.vols;
    titles = p.Results.titles;
    overlap = p.Results.overlap;
    separate = p.Results.separate;
    
    if ismember('overlap', p.UsingDefaults)
        overlap = 1:numel(vols);
    end
    
    if ismember('titles', p.UsingDefaults)
        titles = cellstr(repmat(' ', [numel(vols), 1]));
        titles
    end
    
end
