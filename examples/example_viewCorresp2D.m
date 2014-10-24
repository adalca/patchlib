function example_viewCorresp2D(varargin)

    % prepare tests
    [testids, im, noisyim, patchSize] = setup(varargin{:});
    
    if ismember(1, testids)
        % perform a knn search for sliding patches in noisyim by using im as reference.
        % extract patches in a [nPatches x V] matrix, where V == prod(patchSize)
        [~, ~, pIdx, pRefIdxs, srcgridsize, refgridsize] = ...
            patchlib.volknnsearch(noisyim, im, patchSize, 'K', 1);

        % visualize correspondances
        patchview.corresp2D(pIdx, refgridsize, srcgridsize, 'refIndex', pRefIdxs);
    end
    
    if ismember(1, testids)

        % try 2 references
        refs = {im, normrnd(im, 0.05)};
        [~, ~, pIdx, pRefIdxs, srcgridsize, refgridsize] = ...
            patchlib.volknnsearch(noisyim, refs, patchSize, 'K', 1);
        patchview.corresp2D(pIdx, refgridsize, srcgridsize, 'refIndex', pRefIdxs);
    end
    
end

function [testids, im, noisyim, patchSize] = setup(varargin)

    % decide on tests
    testids = ifelse(nargin == 0, '1:2', 'varargin{1}', true);
        
    % get noise standard deviation
    noisestd = ifelse(nargin < 2, '0.05', 'varargin{2}', true);
    
    % load image. We'll crop around a small pepper.
    imd = im2double(imread('peppers.png'));
    im = rgb2gray(imresize(imd(220:320, 100:200, :), [25, 25]));
    patchSize = [3, 3];
    
    % simulate a noisy image
    noisyim = normrnd(im, noisestd); 
end
