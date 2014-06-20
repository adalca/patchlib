function example_stackPatches(varargin)
% TESTSTACKPATCHES Test stackPatches on simple reconstruction task.
%   testStackPatches() Test stackPatches on simple reconstruction task, running all tests.
%
%       We take (a small part) of the peppers.png image, we add noise to it, and then do a knnsearch
%       to search for the nearest neighbourin the non-noisy image to attempt to reconstruct the
%       noisy image. Of course, for reconstruction this is cheating, but it allows a nice
%       illustration of the patch stack. We use a very small part of peppers.png since our goal is
%       to illustrate how the layers break into patches.
% 
%       tests:
%       1. show the layers in subplots.
%       2. show the layers stacked in 3d.
%       3. show the layers stacked in 3d, with layer transparency of 1 ./ nLayers. This will
%       make each layer fairly transparent. However, if you spin the axis interactively to look
%       at the layers head-on, the 'average image' accross all layers will be seen :)
%       4. show the reconstruction quality by just averaging the layers (which will be the same
%       result as the interactive exercise in test 3)
%
%   testStackPatches(testids) run just the test numbers in testids
%
%   testStackPatches(testids, noisestd) specify the noise standard deviation for 
%       the simulated noisy image.
%       
% Contact: adalca@mit.edu
    
    % prepare tests
    [testids, im, noisyim, patchSize] = setup(varargin{:});
    
    % perform a knn search for sliding patches in noisyim by using im as reference.
    % extract patches in a [nPatches x V] matrix, where V == prod(patchSize)
    patches = patchlib.volknnsearch(noisyim, im, patchSize, 'K', 1);
    gridsize = patchlib.gridsize(size(im), patchSize);
    
    % assemble the patches into layers
    layers = patchlib.stackPatches(patches, patchSize, gridsize);

    %%% Test 1
    if ismember(1, testids)
        patchview.layers2D(layers, 'discrete', patchSize);
    end
    
    %%% Test 2
    if ismember(2, testids)
        patchview.layers2D(layers, 'stack');
    end
    
    %%% Test 3
    if ismember(3, testids)
        patchview.layers2D(layers, 'stack', 1 ./ size(layers, 1));
        title(sprintf('Stack of patch layers as given by stackPatches, with transparency. \n%s', ...
            'For a cute effect, use the Rotate3D tool to see the layers head on'));        
    end
    
    %%% Test 4
    if ismember(4, testids)

        % show the final image 
        patchview.figure(); 

        subplot(1, 3, 1);
        imshow(im); 
        title('original image')

        subplot(1, 3, 2);
        imshow(noisyim); 
        title('noisy image')

        subplot(1, 3, 3);
        vol = squeeze(nanmean(layers, 1));
        imshow(vol); % (..., 'InitialMagnification', 'fit');
        title('resulting image of mean-votes of first NN');
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
