function varargout = patchesInImage(im, patchSize, patchLoc, varargin)
% VIEWPATCHESINIMAGE visualize 2D patches in an image
%   viewPatchesInImage(im, patchSize, patchLoc) visualize 2D patches given by patchLoc 
%   as part of the given image im. Half of the resulting figure will display the image, with colored
%   rectangles indicating patch locations. The other half of the resulting figure will show the
%   patches organized in a subplot grid. 
%       im: the 2D image (grayscale or rgb)
%       patchLoc: [nPatches x 2] matrix
%       patchSize: [1 x 2] vector of the size of the patches
%
%   viewPatchesInImage(..., patchIndexing) allows to specify if patch indexing should be 'top-left'
%       (default) or 'center'
%
%   viewPatchesInImage(..., true) allows for interactive patch creation and
%   deletion:
%       left-click in the image subplot will create a patch base on that location
%       left-click in a patch subplot will de-select (remove rectangles) of that patch
%       right-click in the patch subplot will remove that patch.
%
%   patches = viewPatchesInImage(...) returns the patches structure array, which includes the
%   fields:
%       vol - the patch volume
%       start - the starting point in the image space as drawn on the canvas
%       loc - the patch location
%       rectInImage - the object handle of the drawn rectangle in the Image space
%       rect - the rectangle object handle in the patch rendering
%       color - [1 x 3] rgb color used to draw the rectangle for this patch.
%
%   Example: [see more @ patchlib.testViews()]
%       im = imresize(im2double(imread('peppers.png')), [75, 75]);
%       pv = patchlib.view;
%       patchLoc = [7, 7; 25, 23; 17, 29; 37, 13; 10, 10];
%       patchSize = [7, 7];
%       pv.patchesInImage(im, patchLoc, patchSize);
%
% Notes:
%   - Coding: we use 100 character line limit
%   - Interactive mode warning: this function will close all other figures, due to a matlab bug
%   whereby having previous figures and using ginput, followed by closing the current figure crashed
%   matlab with a system error :(
%
% Contact: adalca@csail.mit.edu
    
    
    narginchk(3, 5);
    
    % interactive mode
    interactive = false;
    if nargin == 4 && islogical(varargin{1}) || nargin == 5 && islogical(varargin{2})
        interactive = varargin{end};
        if interactive
            % unfortunately, need to close all other windows -- otherwise, 
            % when closing the current window in interactive mode crashes matlab with a system error.
            % > figure(1); figure(2); ginput(); 
            % followed by a close of figure 2 causes such a crash :(
            close all force;
        end
    end
    
    % patch indexing mode
    idxmode = 'top-left';
    if nargin >= 4 && ischar(varargin{1})
        idxmode = varargin{1};
    end
    
    % setup image
    if ~iscell(im); im = {im ./ max(im(:))}; end
    assert(all(size(im) == [1, 1]) || all(size(im) == [1, 2]) || all(size(im) == [2, 2]));
    for i = 1:numel(im), if ~isempty(im{i}), im{i} = im{i} ./ max(im{i}(:)); end; end
    
    % setup
    nPatches = size(patchLoc, 1);
    nMaxUniqueColors = 10000;
    setup.nElems = max(ceil(sqrt(nPatches)), 1);
    setup.colors = jitter(nMaxUniqueColors);
    setup.usedColors = false(nMaxUniqueColors, 1);
    setup.immatsz = size(im);

    
    % extract patches
    patches = struct('vol', [], 'start', [], 'loc', [], 'size', [], ...
        'rectInImage', [], 'rect', [], 'colidx', []);
    patches(1) = [];
    if nPatches > 0
        for i = 1:nPatches
            patches(i) = prepDrawPatch(patchLoc(i, :), patchSize, im{1}, idxmode);
        end
    end
    
    % show image and patches
    setup.h.main = patchlib.figview();
    [patches, setup] = drawAllPatches(patches, setup, im);
    usedColors(1:nPatches) = true;
    figure(setup.h.main);
    
    % start interactive process if requested.
    while interactive
        subplot(setup.immatsz(1), setup.immatsz(2) + 1, 1);
        mainmsg = 'Click in main image (left subplot): add patch located at click';
        patchmsg = 'Click on patch in patches grid: Left-click: ''deselect'', Right-click: delete';
        title(sprintf('%s\n%s\n', mainmsg, patchmsg));
        
        try
            % get the input - x, y, and mouse button used
            clear x y
            [x, y, button] = ginput(1);
            assert(numel(x) == 1 && x > 0, 'patchLib:CleanFigClose', 'unexpected input');
            assert(numel(y) == 1 && y > 1, 'patchLib:CleanFigClose', 'unexpected input');
            x = round(x);
            y = round(y);
            clickedAx = gca;
            
            switch clickedAx      
                
                % if clicked on the main image, generate a new patch based on click
                case setup.h.image
                    patch = prepDrawPatch([y, x], patchSize, im{1}, idxmode);
                    nPatches = nPatches + 1;
                    newNElems = ceil(sqrt(nPatches));
                    
                    % if the new patch fits in the subplot grid, then just add it
                    if newNElems == setup.nElems
                        patch.colidx = find(~setup.usedColors, 1, 'first');
                        setup.usedColors(patch.colidx) = true;
                        [patch.rectInImage, patch.rect, setup.h.plots(nPatches)] ...
                            = drawPatch(patch, nPatches, setup, size(im{1}));
                        
                        patches(nPatches) = patch;
                        
                    % if need more rows/columnes of subplots, need to re-draw everything
                    else
                        setup.nElems = newNElems;
                        patches(nPatches) = patch;
                        [patches, setup] = drawAllPatches(patches, setup, im);
                        usedColors(1:nPatches) = true;
                    end
                    
                % if clicking on a patch, erase that patch
                case num2cell(setup.h.plots)
                    idx = find(setup.h.plots == clickedAx);
                    
                    % if right click (or middle click), completely remove this patch
                    if any(button == [2, 3])
                        delete(patches(idx).rectInImage);
                        delete(patches(idx).rect);
                        cla(setup.h.plots(idx));
                        patches(idx) = [];
                        setup.h.plots = [];
                        usedColors(idx) = false;
                        nPatches = nPatches - 1;
                        [patches, setup] = drawAllPatches(patches, setup, im);
                        
                    % if left click just remove the rectangles or add them back.
                    else
                        % remove rectangles if they exist
                        if ~isempty(patches(idx).rectInImage)
                            delete(patches(idx).rectInImage);
                            patches(idx).rectInImage = [];
                            delete(patches(idx).rect);
                            patches(idx).rect = [];
                        
                        % draw this patch if no rectangles exist
                        else
                            [patches(idx).rectInImage, patches(idx).rect, setup.h.plots(idx)] ...
                                = drawPatch(patches(idx), idx, setup, size(im));
                        end
                    end
                    
                otherwise
                    error('view.patchesInImage: click location not understood');
            end
            
        % re-throw error unless it's one of the pre-specified ones, which just indicate a clean exit
        catch err
            okids = {'MATLAB:ginput:FigureDeletionPause', ...
                'MATLAB:ginput:FigureUnavailable', ...
                'patchLib:CleanFigClose'};
            if ~any(strcmp(err.identifier, okids))
                rethrow(err)
            end
            break;
        end
    end
    
    % if caller asking for output
    if nargout == 1
        
        % add the color field
        for i = 1:nPatches
            patches(i).color = setup.colors(patches(i).colidx, :);
        end
        
        % remove colidx field
        patches = rmfield(patches, 'colidx');
        
        % add patches return
        varargout{1} = patches;
    end
    
end


function patch = prepDrawPatch(patchLoc, patchSize, im, idxmode)
% compute the patch struct. 
%   patch.vol - extracted patch from image
%   patch.setart - starting corner of the patch in the image
%   empty fields: rectInImage, rect, colidx. These will be assigned at drawing time.
    
    switch idxmode
        case 'center'
            s = patchLoc - (patchSize - 1) / 2;
        case 'top-left'
            s = patchLoc;
        otherwise
            error('wrong indexing mode: %s', idxmode);
    end
    e = s + patchSize - 1;        
    y = s(1):e(1);
    x = s(2):e(2);
    patch.vol = im(y, x, :);
    patch.start = [s(1)-0.5, s(2)-0.5];
    patch.loc = patchLoc;
    patch.size = [numel(y), numel(x)];
    
    patch.rectInImage = [];
    patch.rect = [];
    patch.colidx = 0;
    
end


function [rectInImage, rect, subploth] = drawPatch(patch, idx, setup, ~)
% draw given patch (with index idx in the patches structure)
    
    color = setup.colors(patch.colidx, :);
    nElems = setup.nElems;
    sz = setup.immatsz;
    
    % draw rectangle in image
    subplot(sz(1), sz(2) + 1, 1); hold on;
    rectInImage = patchlib.drawPatchRect(patch.start, patch.size, color);
      
    % draw patch in subPlot
    col = sz(2) * nElems + mod(idx - 1, nElems) + 1;
    row = ceil(idx ./ nElems);
    didx = sub2ind([(sz(2)+1)*nElems, nElems], col, row);
    subploth = subplot(nElems, (sz(2)+1) * nElems, didx);
    imshow(patch.vol);
    rect = patchlib.drawPatchRect([1, 1], patch.size, color);
end

function [patches, setup] = drawAllPatches(patches, setup, im)
% (re-)draw all patches
    
    sz = setup.immatsz;

    % draw main image(s)
    clf;
    setup.h.image = subplot(size(im, 1), size(im, 2) + 1, 1);
    imp = im'; % use imp to match the cell structure given
    for i = 1:numel(im)
        idx = ind2ind(sz, [sz(1) + 1, sz(2)], i);
        subplot(sz(1), sz(2) + 1, idx);
        imshow(imp{i}); hold on;
    end
    imSize = size(im{1});
    
    setup.h.plots = zeros(numel(patches), 1);
    for i = 1:numel(patches)
        
        % if a colidx does not exist, choose one.
        if patches(i).colidx == 0
            patches(i).colidx = find(~setup.usedColors, 1, 'first');
            setup.usedColors(patches(i).colidx) = true;
        end
        
        % draw patch
        [patches(i).rectInImage, patches(i).rect, setup.h.plots(i)] = ...
            drawPatch(patches(i), i, setup, imSize);
    end
end
