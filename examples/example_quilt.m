function example_quilt(varargin)
% EXAMPLE_QUILT patchlib quilt example 
%   example_quilt() of using patchlib and patchview functions for a trivial reconstructon task
%
%   example_quilt(exids) - run only a subset of the given example ids in a vector exids
%   default is [1:4]
%
%   example_quilt(exids, noise) - noise std to add to the image. default: 1.0

    pl = patchlib;
    maxCase = 4;

    % setup a crop of the peppers.png image, as well as a noisy version of it
    [exids, im, noisyim, patchSize] = setup(maxCase, varargin{:});
    
    % prepare a zoom-in to show 
    m = round(size(im)/2);
    spacing = 15;
    subrange = {m(1)-spacing:m(1)+spacing, m(2)-spacing:m(2)+spacing, 1:size(im, 3)};
    
    nRows = maxCase+1;
    nCols = 3;
    
    
    % show the initial image
    patchview.figure(); 
    
    subplot(nRows, nCols, 1);
    imshow(im); 
    title('original image')
    
    subplot(nRows, nCols, 2);
    imshow(noisyim); 
    title('noisy image')
    
    subplot(nRows, nCols, 3);
    imshow(noisyim(subrange{:})); 
    title('noisy image')
    drawnow();
    
    % test sliding spacing with averaging
    if ismember(1, exids)
        
        % perform a knn search for mrf patches in noisyim by using im as reference.
        % extract patches in a [gridSize x V] matrix, where V == prod(patchSize)
        [patches, pDst, ~, ~, gridSize] = pl.volknnsearch(noisyim, im, patchSize, 'K', 10);
        vol = pl.quilt(patches, gridSize, 'sliding');
        
        weights = exp(-pDst);
        volw = pl.quilt(patches, gridSize, 'sliding', 'nnWeights', weights);
        
        subplot(nRows, nCols, nCols*1 + 1);
        imshow(vol, 'InitialMagnification', 'fit');
        title(sprintf('sliding grid, mean(mean) %3.2f', nanssd(vol(:), im(:))));
        
        subplot(nRows, nCols, nCols*1 + 2);
        imshow(volw, 'InitialMagnification', 'fit');
        title(sprintf('sliding grid, mean(wmean) %3.2f', nanssd(volw(:), im(:))));
        
        subplot(nRows, nCols, nCols*1 + 3);
        imshow(volw(subrange{:}), 'InitialMagnification', 'fit');
        title('sliding grid, mean(wmean)');
        drawnow();
    end
    
    % test MRF spacing with normal averaging, K = 1
    if ismember(2, exids)
        % perform a knn search for mrf patches in noisyim by using im as reference.
        % extract patches in a [gridSize x V] matrix, where V == prod(patchSize)
        [patches, pDst, ~, ~, gridSize] = pl.volknnsearch(noisyim, im, patchSize, 'mrf', 'K', 10);
        vol = pl.quilt(patches, gridSize, 'mrf');
        
        weights = exp(-pDst);
        volw = pl.quilt(patches, gridSize, 'mrf', 'nnWeights', weights);
        
        subplot(nRows, nCols, nCols*2 + 1);
        imshow(vol, 'InitialMagnification', 'fit');
        title(sprintf('mrf grid, mean(mean) %3.2f', nanssd(vol(:), im(:))));
        drawnow();
        
        subplot(nRows, nCols, nCols*2 + 2);
        imshow(volw, 'InitialMagnification', 'fit');
        title(sprintf('mrf grid, mean(wmean) %3.2f', nanssd(volw(:), im(:))));
        
        subplot(nRows, nCols, nCols*2 + 3);
        imshow(volw(subrange{:}), 'InitialMagnification', 'fit');
        title('mrf grid, mean(wmean)');
        drawnow();
    end
    
    % test MRF spacing with MRF inference
    if ismember(3, exids)
        % perform a knn search for mrf patches in noisyim by using im as reference.
        % extract patches in a [gridSize x V] matrix, where V == prod(patchSize)
        [patches, pDst, ~, ~, gridSize] = pl.volknnsearch(noisyim, im, patchSize, 'mrf', 'K', 10);
        
        % TODO: combine the next 3 mini blocks into patchmrf...
        [qpatches, bel, pot] = pl.patchmrf(patches, gridSize, pDst);
        
        % quilt bland
        vol = pl.quilt(qpatches, gridSize, 'mrf');
        
        % quilt with weights
        gaussFilt = fspecial('gaussian', patchSize);
        w1 = repmat(gaussFilt(:)', [size(qpatches, 1), 1]);
        w2 = repmat(max(bel.nodeBel, [], 2), [1, size(w1, 2)]);
        volw = pl.quilt(qpatches, gridSize, 'mrf', 'weights', w1 .* w2);
        
        subplot(nRows, nCols, nCols*3 + 1);
        imshow(vol, 'InitialMagnification', 'fit');
        title(sprintf('mrf grid, mean(lbp) %3.2f', nanssd(vol(:), im(:))));
        drawnow();
        
        subplot(nRows, nCols, nCols*3 + 2);
        imshow(volw, 'InitialMagnification', 'fit');
        title(sprintf('mrf grid, wmean(lbp) %3.2f', nanssd(volw(:), im(:))));
        
        subplot(nRows, nCols, nCols*3 + 3);
        imshow(volw(subrange{:}), 'InitialMagnification', 'fit');
        title('mrf grid, mean(lbp) ');
        drawnow();
    end
    

    
    % test MRF local search with MRF inference
    if ismember(4, exids)
        % perform a knn search for local mrf patches in noisyim by using im as reference.
        % extract patches in a [gridSize x V] matrix, where V == prod(patchSize)
        [patches, pDst, ~, ~, gridSize] = pl.volknnsearch(noisyim, im, patchSize, 'mrf', ...
            'local', 3, 'K', 10);
        
        % TODO: combine the next 3 mini blocks into patchmrf...
        [qpatches, bel] = pl.patchmrf(patches, gridSize, pDst);
        
        % quilt bland
        vol = pl.quilt(qpatches, gridSize, 'mrf');
        
        % quilt with weights
        gaussFilt = fspecial('gaussian', patchSize);
        w1 = repmat(gaussFilt(:)', [size(qpatches, 1), 1]);
        w2 = repmat(max(bel.nodeBel, [], 2), [1, size(w1, 2)]);
        volw = pl.quilt(qpatches, gridSize, 'mrf', 'weights', w1 .* w2);
        
        subplot(nRows, nCols, nCols*4 + 1);
        imshow(vol, 'InitialMagnification', 'fit');
        title(sprintf('mrf grid, mean(lbp) %3.2f', nanssd(vol(:), im(:))));
        drawnow();
        
        subplot(nRows, nCols, nCols*4 + 2);
        imshow(volw, 'InitialMagnification', 'fit');
        title(sprintf('mrf grid, wmean(lbp) %3.2f', nanssd(volw(:), im(:))));
        
        subplot(nRows, nCols, nCols*4 + 3);
        imshow(volw(subrange{:}), 'InitialMagnification', 'fit');
        title('mrf grid, mean(lbp) ');
        drawnow();
    end
    
end


function [exids, im, noisyim, patchSize] = setup(maxCase, varargin)

    % decide on tests
    exids = ifelse(nargin == 1, ['1:', num2str(maxCase)], 'varargin{1}', true);
        
    % get noise standard deviation
    noisestd = ifelse(nargin < 3, '0.1', 'varargin{2}', true);
    
    % load image. We'll crop around a small pepper.
    imd = im2double(imread('peppers.png'));
    im = rgb2gray(imresize(imd(220:320, 100:200, :), [101, 101]));
    patchSize = [5, 5];
    
    % simulate a noisy image
    noisyim = normrnd(im, noisestd); 
end
