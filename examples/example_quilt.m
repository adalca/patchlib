function example_quilt(varargin)
% EXAMPLE_QUILT patchlib quilt example 
%   example_quilt() of using patchlib and patchview functions for a trivial reconstructon task
%
%   example_quilt(exids) - run only a subset of the given example ids in a vector exids
%   default is [1:4]
%
%   example_quilt(exids, noise) - noise std to add to the image. default: 0.1
%
%   TODO: do a tutorial/example. use also publish!
%       and publish the results of publish on the github page
%   TODO: do the steps of volknnsearch! to show how to use the other functions
%       i.e. in its simplest: vol2lib for src and refs, knnsearch, lib2patches
%       exaplain that this is global, we allow local, etc.
%       That's why this function is more about testing than example...


    pl = patchlib;

    % setup a crop of the peppers.png image, as well as a noisy version of it
    [exids, imgs, patchSize] = setup(varargin{:});
        
    % initiate figure
    nRows = numel(exids) + 1;
    patchview.figure(); 
    
    % show the original image, noisy image and a zoom of the noisy image
    ims = {imgs.orig, imgs.noisy};
    titles = {'original image', 'noisy image'};
    drawRow(ims, titles);
    
    
    
    % test sliding spacing with averaging
    if ismember(1, exids)
        
        % perform a knn search for mrf patches in imgs.noisy by using imgs.clean as reference.
        % extract patches in a [gridSize x V] matrix, where V == prod(patchSize)
        [patches, pDst, ~, ~, gridSize] = pl.volknnsearch(imgs.noisy, imgs.orig, patchSize, 'K', 10);
        
        % quilt
        ims{1} = pl.quilt(patches, gridSize, 'sliding');
        titles{1} = sprintf('sliding grid, mean(mean) %3.2f', nanssd(ims{1}(:), imgs.orig(:)));
        
        % quilt with 
        ims{2} = pl.quilt(patches, gridSize, 'sliding', 'nnWeights', exp(-pDst));
        titles{2} = sprintf('sliding grid, mean(wmean) %3.2f', nanssd(ims{2}(:), imgs.orig(:)));
        
        % draw
        drawRow(ims, titles, 1);
    end
    
    
    
    % test MRF spacing with normal averaging, K = 10?
    if ismember(2, exids)
        % perform a knn search for mrf patches in imgs.noisy by using im as reference.
        % extract patches in a [gridSize x V] matrix, where V == prod(patchSize)
        [patches, pDst, ~, ~, gridSize] = pl.volknnsearch(imgs.noisy, imgs.orig, patchSize, 'half', 'K', 10);
        ims{1} = pl.quilt(patches, gridSize, 'half');
        titles{1} = sprintf('mrf grid, mean(mean) %3.2f', nanssd(ims{1}(:), imgs.orig(:)));
        
        ims{2} = pl.quilt(patches, gridSize, 'half', 'nnWeights', exp(-pDst));
        titles{2} = sprintf('mrf grid, mean(wmean) %3.2f', nanssd(ims{2}(:), imgs.orig(:)));
        
        % draw
        drawRow(ims, titles, 2);
    end
    
    
    
    % test MRF spacing with MRF inference
    if ismember(3, exids)
        % perform a knn search for mrf patches in imgs.noisy by using im as reference.
        % extract patches in a [gridSize x V] matrix, where V == prod(patchSize)
        [patches, pDst, ~, ~, gridSize] = pl.volknnsearch(imgs.noisy, imgs.orig, patchSize, 'half', 'K', 10);
        
        % TODO: combine the next 3 mini blocks into patchmrf...
        [qpatches, bel, ~] = pl.patchmrf(patches, gridSize, pDst);
        
        % quilt bland
        ims{1} = pl.quilt(qpatches, gridSize, 'half');
        titles{1} = sprintf('mrf grid, mean(lbp) %3.2f', nanssd(ims{1}(:), imgs.orig(:)));
        
        % quilt with weights
        gaussFilt = fspecial('gaussian', patchSize);
        w1 = repmat(gaussFilt(:)', [size(qpatches, 1), 1]);
        w2 = repmat(max(bel.nodeBel, [], 2), [1, size(w1, 2)]);
        ims{2} = pl.quilt(qpatches, gridSize, 'half', 'weights', w1 .* w2);
        titles{2} = sprintf('mrf grid, wmean(lbp) %3.2f', nanssd(ims{2}(:), imgs.orig(:)));
        
        % draw
        drawRow(ims, titles, 3);
    end
    

    
    % test MRF local search with MRF inference
    if ismember(4, exids)
        % perform a knn search for local mrf patches in imgs.noisy by using im as reference.
        % extract patches in a [gridSize x V] matrix, where V == prod(patchSize)
        [patches, pDst, ~, ~, gridSize] = pl.volknnsearch(imgs.noisy, imgs.orig, patchSize, 'half', ...
            'local', 3, 'K', 10);
        
        % TODO: combine the next 3 mini blocks into patchmrf...
        [qpatches, bel] = pl.patchmrf(patches, gridSize, pDst);
        
        % quilt bland
        ims{1} = pl.quilt(qpatches, gridSize, 'half');
        titles{1} = sprintf('mrf grid, local, mean(lbp) %3.2f', nanssd(ims{1}(:), imgs.orig(:)));
        
        % quilt with weights
        gaussFilt = fspecial('gaussian', patchSize);
        w1 = repmat(gaussFilt(:)', [size(qpatches, 1), 1]);
        w2 = repmat(max(bel.nodeBel, [], 2), [1, size(w1, 2)]);
        ims{2} = pl.quilt(qpatches, gridSize, 'half', 'weights', w1 .* w2);
        titles{2} = sprintf('mrf grid, local, wmean(lbp) %3.2f', nanssd(ims{2}(:), imgs.orig(:)));
        
        % draw
        drawRow(ims, titles, 4);
    end
    
    
    
    function drawRow(ims, titles, exid) %#ok<INUSD>
        
        rowid = ifelse(nargin == 2, '1', 'find(exid == exids) + 1', true);
        ims{end + 1} = ims{2}(imgs.subrange{:});
        titles{end + 1} = [titles{end}, '  zoom'];
        examples_drawRow(nRows, rowid, ims, titles)
    end
    
end


function [exids, imgs, patchSize] = setup(varargin)

    % number of possible examples 
    exmax = 4;

    % decide on tests
    exids = ifelse(nargin == 0, ['1:', num2str(exmax)], 'varargin{1}', true);
        
    % get noise standard deviation
    noisestd = ifelse(nargin < 3, '0.1', 'varargin{2}', true);
    
    % load image. We'll crop around a small pepper.
    imd = im2double(imread('peppers.png'));
    imgs.orig = rgb2gray(imresize(imd(220:320, 100:200, :), [101, 101]));
    patchSize = [5, 5];
    
    % simulate a noisy image
    imgs.noisy = normrnd(imgs.orig, noisestd); 
    
    % prepare a zoom-in to show 
    m = round(size(imgs.orig)/2);
    spacing = 15;
    imgs.subrange = {m(1)-spacing:m(1)+spacing, m(2)-spacing:m(2)+spacing, 1:size(imgs.orig, 3)};
end


