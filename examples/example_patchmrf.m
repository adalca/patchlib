function example_patchmrf(varargin)
% TODO: do some more serious example where you learn from a second image
%   especially medical images where can use location

    [testids, im, noisyim, patchSize] = setup(varargin{:});
    
    if ismember(1, testids)
        % perform a knn search for mrf patches in noisyim by using im as reference.
        % extract patches in a [nPatches x V] matrix, where V == prod(patchSize)
        [patches, pDst, ~, ~, srcgridsize] = ...
            patchlib.volknnsearch(noisyim, im, patchSize, 'mrf', 'K', 10);
        
        qpatches = patchlib.patchmrf(patches, srcgridsize, pDst);
        resimg = patchlib.quilt(qpatches, srcgridsize, patchSize, 'mrf'); 
        
        subplot(1, 3, 1); imagesc(noisyim);
        subplot(1, 3, 2); imagesc(im);
        subplot(1, 3, 3); imagesc(resimg);
    end
    
    if ismember(2, testids)
        % search for patches with a location difference weight as well
        [patches, pDst, pIdx, ~, srcgridsize, refgridsize] = ...
            patchlib.volknnsearch(noisyim, im, patchSize , 'K', 10, 'location', 0.01);
        
        % quilt an image using the top patch
        resimg1 = patchlib.quilt(patches(:,:,1), srcgridsize, patchSize); 
        
        % run an mrf on
        usemex = exist('pdist2mex', 'file') == 3;
        edgefn = @(a1,a2,a3,a4) patchlib.correspdst(a1, a2, a3, a4, [], usemex); 
        [qp, ~, ~, pi] = ...
            patchlib.patchmrf(patches, srcgridsize, pDst, patchSize , 'edgeDst', edgefn, ...
            'lambda_node', 0.1, 'lambda_edge', 10, 'pIdx', pIdx, 'refgridsize', refgridsize);
        
        disp = patchlib.corresp2disp(srcgridsize, refgridsize, pi);
        resimg2 = patchlib.quilt(qp, srcgridsize, patchSize); 
        
        patchview.figure();
        subplot(2, 3, 1); imagesc(noisyim);
        subplot(2, 3, 2); imagesc(im);
        subplot(2, 3, 3); imagesc(resimg1);
        subplot(2, 3, 4); imagesc(resimg2);
        subplot(2, 3, 5); imagesc(reshape(disp{1}, srcgridsize)); 
        subplot(2, 3, 6); imagesc(reshape(disp{2}, srcgridsize)); 
        
    end
    
end


function [testids, im, noisyim, patchSize] = setup(varargin)

    % decide on tests
    testids = ifelse(nargin == 0, '1:4', 'varargin{1}', true);
        
    % get noise standard deviation
    noisestd = ifelse(nargin < 2, '0.1', 'varargin{2}', true);
    
    % load image. We'll crop around a small pepper.
    imd = im2double(imread('peppers.png'));
    im = imresize(imd(220:320, 100:200, :), [25, 25]); 
    patchSize = [5, 5, 3];
    
    % simulate a noisy image
    noisyim = normrnd(im, noisestd); 
    noisyim = within([0, 1], noisyim);
    im = within([0, 1], im);
end
