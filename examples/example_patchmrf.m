function example_patchmrf(varargin)
    [testids, im, noisyim, patchSize] = setup(varargin{:});
    
    % perform a knn search for mrf patches in noisyim by using im as reference.
    % extract patches in a [nPatches x V] matrix, where V == prod(patchSize)
    [patches, pDst] = patchlib.volknnsearch(noisyim, im, patchSize, 'mrf', 'K', 10);
    gridsize = patchlib.gridsize(size(im), patchSize, 'mrf');
    
    if ismember(1, testids)
        [qpatches, bel, pot] = patchlib.patchmrf(patches, gridsize, pDst);
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
    patchSize = [5, 5];
    
    % simulate a noisy image
    noisyim = normrnd(im, noisestd); 
end
