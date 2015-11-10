function votehist(vol, patches, grididx, patchSize, varargin)
% VOTEHIST see histograms of the votes for specific locations (interactive)
%   votehist(vol, patches, grididx, patchSize) for 2D: vol should be a 2D image, patches are the
%   resulting patches from a knnsearch sized (N x P x K), grididx is the patch grid (see
%   patchlib.grid), and numel(grididx) == N, patchSize is the size of the patch.
%
%   votehist(vol, patches, grididx, patchSize, sliceID) for 3D: vol is 3D, but we will only show
%   slice sliceID;
%
%   votehist(..., Param, Value) allows for the following param/value pairs:
%       method - (default:2) % 1 for colorful, 2 for no color. Colorful is a bit buggy right now.
%       histNBins - (default:10) the number of histogram bins 
%   
%   Note: vol can be any volume that is the size of the original (source) volume on which grididx is
%   built. For example, you may use your desired resulting volume, if you are in a phase where you
%   are training your algorithm.
%
%   Currently, we are showing up to 4 histograms next to the main image.
%
%   Author: adalca@csail.mit.edu
    
    % input checks
    narginchk(4, inf);
    inputs = parseInputs(vol, patches, grididx, patchSize, varargin{:});
    slice = vol(:,:,inputs.slice);
    
    % show slice
    patchview.figure();
    subplot(1, 2, 1);
    imagesc(slice); colormap gray;
    
    % prepare histogram axes and count
    minmax = double([min(slice(:)), max(slice(:))]);
    N = 0;
    rect = zeros(1, 4);
        
    % iteratively ask for user input
    while true
        try
            % get the input - x, y, and mouse button used
            clear x y
            [x, y] = ginput(1);
            assert(numel(x) == 1 && x > 0, 'patchview:CleanFigClose', 'unexpected input');
            assert(numel(y) == 1 && y > 1, 'patchview:CleanFigClose', 'unexpected input');
            x = round(x);
            y = round(y);

            % get votes for this location
            votes = patchlib.locvotes([y, x, inputs.slice], patches, grididx, patchSize, size(vol));
            votes = double(votes);
            
            % if no votes for this area
            if isempty(votes)
                
                title('no votes found');
                continue;
                
            else
                % prepare box colors
                colors = {[1, 0.7, 0.5], [0.7, 0.7, 1], [0.7, 1, 0.7], [1, 0.8, 1]};
                
                % prepare the location of the histogram boxes
                rows = floor(mod(N, 4)/2) + 1;
                cols = 3 + mod(N, 2);
                idx = sub2ind([4, 2], cols, rows);
                subplot(2, 4, idx);
                
                % prepare the hisogram bins
                binc = linspace(minmax(1), minmax(2), inputs.histNBins);
                
                % show histogram based on different methods
                switch inputs.method
                    case 1 % colored based on K (maybe TODO: based on (binned) pDst ?
                                      
                        % get valid Ks and colormap
                        uKsub = unique(Ksub);
                        j = jitter(numel(uKsub));

                        % count histograms
                        h = zeros(histNBins, numel(uKsub));
                        for i = 1:numel(uKsub)
                            h(:, i) = hist(votes(Ksub == i), binc); 
                        end
                        
                        % show colorful bar
                        b = bar(binc, h, 'stacked');
                        for i = 1:numel(uKsub)
                            set(b(i), 'FaceColor', j(i, :));
                        end
                        
                    case 2
                        % get and draw histogram
                        hist(votes, binc);     
                end
                        
                % get the box color of the hisogram to match the voxel.
                set(gca, 'Color', colors{mod(N, 4)+1})
                clickint = slice(y, x);
                meanint = mean(votes(:));
                medianint = median(votes(:));
                msint = nan; 
                try msint = meanShift(votes(:)); catch err, end
                minint = min(votes(:));
                title(sprintf('clicked:%3.2f, vmean:%3.2f, vmed:%3.2f, ms:%3.2f, min:%3.2f', ...
                    clickint, meanint, medianint, msint, minint));
                hold off;
                
                subplot(1, 2, 1);
                if rect(mod(N, 4) + 1) ~= 0
                    delete(rect(mod(N, 4) + 1));
                end
                rect(mod(N, 4) + 1) = patchview.drawPatchRect([y,x], [1, 1], colors{mod(N, 4)+1});
                title(sprintf('#votes:%d, Intensity: %3.2f', numel(votes), slice(y, x)));
                
                % increase box count.
                N = N + 1;
            end
        
        % re-throw error unless it's one of the pre-specified ones, which just indicate a clean exit
        catch err
            okids = {'MATLAB:ginput:FigureDeletionPause', ...
                'MATLAB:ginput:FigureUnavailable', ...
                'patchview:CleanFigClose', ...
                'MATLAB:ginput:Interrupted'};
            if ~any(strcmp(err.identifier, okids))
                rethrow(err)
            end
            break;
        end
    end
    
end

function inputs = parseInputs(vol, patches, grididx, patchSize, varargin)

    nDims = ndims(vol);
    assert(nDims == 2 || nDims == 3, 'Currently only implemented for 2D or 3D');

    p = inputParser();
    p.addRequired('vol', @isnumeric);
    p.addRequired('patches', @(x) size(x, 1) == numel(grididx));
    p.addRequired('grididx', @(x) max(x) <= numel(vol));
    p.addRequired('patchSize', @isnumeric);
    if nDims == 3
        p.addRequired('slice', @isnumeric)
    end
    p.addParameter('method', 2, @isscalar); % 1 for colorful, 2 for no color. Colorful is a bit buggy right now.
    p.addParameter('histNBins', 10, @isscalar); % could learn this in some meaningful way.
    p.parse(vol, patches, grididx, patchSize, varargin{:})
    inputs = p.Results;

    if nDims == 2
        inputs.slice = 1;
    end
end
