function example_viewPatchRef2D(varargin)

    % prepare tests
    nPts = 5;
    [testids, im, noisyim, patchSize] = setup(varargin{:});
    
    % perform a knn search for sliding patches in noisyim by using im as reference.
    % extract patches in a [nPatches x V] matrix, where V == prod(patchSize)
    [~, pIdx, rIdx] = patchlib.volknnsearch(noisyim, im, patchSize, 'K', 1);
    
    
    vIdx = randperm(size(pIdx, 1))';
    
    if ismember(1, testids)
        v = vIdx(1:nPts);
        p = pIdx(vIdx(1:nPts), :);
        r = rIdx(vIdx(1:nPts), :);
        patchview.patchRef2D(noisyim, im, v, p, r, patchSize);
    end
    
end

function [testids, im, noisyim, patchSize] = setup(varargin)

    % decide on tests
    testids = ifelse(nargin == 0, '1:4', 'varargin{1}', true);
        
    % get noise standard deviation
    noisestd = ifelse(nargin < 2, '0.1', 'varargin{2}', true);
    
    % load image. We'll crop around a small pepper.
    imd = im2double(imread('peppers.png'));
    im = rgb2gray(imresize(imd(220:320, 100:200, :), [25, 25]));
    patchSize = [3, 3];
    
    % simulate a noisy image
    noisyim = normrnd(im, noisestd); 
end
