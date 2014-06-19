function rect = drawPatchRect(patchloc, patchSize, color)
% DRAWPATCHRECT draw rectangles around a patch in the current axis
%   rect = drawPatchRect(patchloc, patchSize) draw rectangles around a patch in the current axis.
%   patchloc is a Nx2 vec: [y, x] (note that this is opposite of matlab usual 2D notation. We do
%   this to keep with usual n-d notation). patchSize is 1x2 or Nx2 vector [y_i, x_i]. Returns the
%   rectangle object.
%
%   rect = drawPatchRect(patchloc, patchSize) allows for the specification of color, a Nx3 or Nx1
%   cell of strings
%   
% Example: 
%   figuresc(); 
%   imagesc(peaks(100)); 
%   colormap gray; 
%   patchlib.drawPatchRect([10, 50; 10, 55], [12, 7], {'r', 'b'});
%
% Contact: adalca@csail.mit.edu
    
    nPatches = size(patchloc, 1);
    if nargin == 2
        color = repmat({'b'}, [nPatches, 1]);
    end
    
    if ~iscell(color)
        if ischar(color); 
            color = {color};
        else
            color = mat2cell(color, ones(size(color, 1)), size(color, 2));
        end
    end
    
    if size(patchSize, 1) == 1
        patchSize = repmat(patchSize, [nPatches, 1]);
    end
    
    % set linewidth to be about 0.1 * size of the pixel
    set(gca,'Units', 'pixels');
    pos = get(gca, 'Position');
    volSize = get(gca, 'xlim');
    lineWidth = 0.1 .* pos(3) ./ diff(volSize);
    
    % draw rectangle around patch in image
    for i = 1:size(patchloc, 1)
        pos = fliplr([patchSize(i, :), patchloc(i, :) - 0.5]);
        rect = rectangle( 'Position', pos, 'LineWidth', lineWidth, 'EdgeColor', color{i});
    end
