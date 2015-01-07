function varargout = patches2D(patches, patchSize, caxisrange, gridtype)
% VIEWPATCHES show 2D patches in a grid
%   viewPatches(patches, patchSize) show 2D patches in a grid. patchSize is a [1 x 2] vector
%       indicating the size of the patches. Given nPixels = prod(patchSize); patches is a 
%       [nPatches x nPixels]. 
%
%       Alternatively, patches can be a cell of already-formatted patches.
%
%   viewPatches(patches) or viewPatches(patches, []): viewPatches will attempt to guess the patch
%       size based on factorization. see guessPatchSize
%
%   viewPatches(patches, patchSize, caxisrange) allows the specification of color axis (e.g. [0, 1])
%       for the patches.
%
%   viewPatches(patches, patchSize, caxisrange, 'subplot') forces each patch in a separate subplot.
%       This option can take a long time for large numbers of patches.
%
%   h = viewPatches(...) returns the hangle of the figure
%
%   [h, nElems] = viewPatches(...) also returns the number of rows/columns of subplots.
%
% See Also: guessPatchSize
%
% Contact: adalca@csail.mit.edu

    narginchk(1, 4);
    
    % move patches to cell
    if ~iscell(patches)
        arg = {};
        if nargin > 1 && ~isempty(patchSize)
            arg = {patchSize};
        end
        [patches, patchSize] = patchlib.patchesmat2cell(patches, arg{:});
    end
    
    if nargin < 4
        gridtype = 'grid';
    end

    % default caxisrange is [0, 1];
    if nargin < 3 || isempty(caxisrange)
        caxisrange = [0, 1];
    end

    % get the grid size
    nPatches = numel(patches);
    nElems = ceil(sqrt(nPatches));
    
    % show patches in subplots.
    h = patchview.figure(); hold on;
    if strcmp(gridtype, 'subplot')
        for i = 1:nPatches
            subplot(nElems, nElems, i);
            imshow(patches{i});
            caxis(caxisrange);
            title(sprintf('%d', i));
        end
        
    % or show patches in an image on a grid.
    else
        % make sure the option is grid
        assert(strcmp(gridtype, 'grid'))
        
        % get patchSize if it has not been computed yet
        if ~exist('patchSize', 'var') || isempty(patchSize)
            patchSize = size(patches{1});
            patchSize = patchSize(1:2); % avoid rgb if color patches
            assert(size(patchSize, 3) == 1 || size(patchSize, 3) == 3);
        end
        
        % build an image
        im = zeros([nElems * patchSize(1:2), size(patches{1}, 3)], class(patches{1}));
        for i = 1:nPatches
            [r, c] = ind2sub([nElems, nElems], i);
            xRange = (c-1)*patchSize(2)+1:c*patchSize(2);
            yRange = (r-1)*patchSize(1)+1:r*patchSize(1);
            im(yRange, xRange, :) = patches{i};
        end
        
        % show the image
        imshow(im, 'InitialMagnification', 'fit'); 
        caxis(caxisrange);
        
        % show the grid
        drawgrid(0.5:patchSize(1):size(im, 1)+1, 0.5:patchSize(2):size(im, 2)+1, 'b');
    end
    
    % prepare outputs
    vargs = {h, nElems};
    varargout = vargs(1:nargout);
end
