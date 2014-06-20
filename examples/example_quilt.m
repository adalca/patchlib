function example_quilt(varargin)
    [testids, im, noisyim, patchSize] = setup(varargin{:});
    m = round(size(im)/2);
    range = {m(1)-20:m(1)+20, m(2)-20:m(2)+20, 1:size(im, 3)};
    
    % show the final image 
    patchview.figure(); 

    subplot(4, 3, 1);
    imshow(im); 
    title('original image')

    subplot(4, 3, 2);
    imshow(noisyim); 
    title('noisy image')
    
    subplot(4, 3, 3);
    imshow(noisyim(range{:})); 
    title('noisy image')
    drawnow();
    
    if ismember(1, testids)
        
        % perform a knn search for mrf patches in noisyim by using im as reference.
        % extract patches in a [gridSize x V] matrix, where V == prod(patchSize)
        [patches, pDst] = patchlib.volknnsearch(noisyim, im, patchSize, 'K', 10);
        gridSize = patchlib.gridsize(size(im), patchSize);
        
        vol = patchlib.quilt(patches, gridSize, 'sliding');
        
        weights = exp(-pDst);
        volw = patchlib.quilt(patches, gridSize, 'sliding', 'nnWeights', weights);
        
        subplot(4, 3, 4);
        imshow(vol, 'InitialMagnification', 'fit');
        title(sprintf('sliding grid, mean(mean) %3.2f', nanssd(vol(:), im(:))));
        
        subplot(4, 3, 5);
        imshow(volw, 'InitialMagnification', 'fit');
        title(sprintf('sliding grid, mean(wmean) %3.2f', nanssd(volw(:), im(:))));
        
        subplot(4, 3, 6);
        imshow(volw(range{:}), 'InitialMagnification', 'fit');
        title('sliding grid, mean(wmean)');
        drawnow();
    end
    
    
    % test MRF
    if ismember(2, testids)
        % perform a knn search for mrf patches in noisyim by using im as reference.
        % extract patches in a [gridSize x V] matrix, where V == prod(patchSize)
        [patches, pDst] = patchlib.volknnsearch(noisyim, im, patchSize, 'mrf', 'K', 10);
        gridSize = patchlib.gridsize(size(im), patchSize, 'mrf');
        
        % TODO: combine the next 3 mini blocks into patchmrf...
        [qpatches, bel, pot] = patchlib.patchmrf(patches, gridSize, pDst);
        
        % quilt bland
        vol = patchlib.quilt(qpatches, gridSize, 'mrf');
        
        % quilt with weights
        gaussFilt = fspecial('gaussian', patchSize);
        w1 = repmat(gaussFilt(:)', [size(qpatches, 1), 1]);
        w2 = repmat(max(bel.nodeBel, [], 2), [1, size(w1, 2)]);
        volw = patchlib.quilt(qpatches, gridSize, 'mrf', 'weights', w1 .* w2);
        
        subplot(4, 3, 7);
        imshow(vol, 'InitialMagnification', 'fit');
        title(sprintf('mrf grid, mean(lbp) %3.2f', nanssd(vol(:), im(:))));
        drawnow();
        
        subplot(4, 3, 8);
        imshow(volw, 'InitialMagnification', 'fit');
        title(sprintf('mrf grid, wmean(lbp) %3.2f', nanssd(volw(:), im(:))));
        
        subplot(4, 3, 9);
        imshow(volw(range{:}), 'InitialMagnification', 'fit');
        title('mrf grid, mean(lbp) ');
        drawnow();
    end
    
    % test MRF spacing with normal averaging, K = 1
    if ismember(3, testids)
        % perform a knn search for mrf patches in noisyim by using im as reference.
        % extract patches in a [gridSize x V] matrix, where V == prod(patchSize)
        [patches, pDst] = patchlib.volknnsearch(noisyim, im, patchSize, 'mrf', 'K', 10);
        gridSize = patchlib.gridsize(size(im), patchSize, 'mrf');
        
        vol = patchlib.quilt(patches, gridSize, 'mrf');
        
        weights = exp(-pDst);
        volw = patchlib.quilt(patches, gridSize, 'mrf', 'nnWeights', weights);
        
        subplot(4, 3, 10);
        imshow(vol, 'InitialMagnification', 'fit');
        title(sprintf('mrf grid, mean(mean) %3.2f', nanssd(vol(:), im(:))));
        drawnow();
        
        subplot(4, 3, 11);
        imshow(volw, 'InitialMagnification', 'fit');
        title(sprintf('mrf grid, mean(wmean) %3.2f', nanssd(volw(:), im(:))));
        
        subplot(4, 3, 12);
        imshow(volw(range{:}), 'InitialMagnification', 'fit');
        title('mrf grid, mean(wmean)');
        drawnow();
    end
    
end


function [testids, im, noisyim, patchSize] = setup(varargin)

    % decide on tests
    testids = ifelse(nargin == 0, '1:4', 'varargin{1}', true);
        
    % get noise standard deviation
    noisestd = ifelse(nargin < 2, '0.07', 'varargin{2}', true);
    
    % load image. We'll crop around a small pepper.
    imd = im2double(imread('peppers.png'));
    im = rgb2gray(imresize(imd(220:320, 100:200, :), [101, 101]));
    patchSize = [5, 5];
    
    % simulate a noisy image
    noisyim = normrnd(im, noisestd); 
end



