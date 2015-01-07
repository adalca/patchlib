function example_patchmrf(varargin)
% TODO: do some more serious example where you learn from a second image
%   especially medical images where can use location

    [testids, refim, noisyim, trueim, patchSize] = setup(varargin{:});
    
    if ismember(1, testids)
        % perform a knn search for mrf patches in noisyim by using im as reference.
        % extract patches in a [nPatches x V] matrix, where V == prod(patchSize)
        [patches, pDst, ~, ~, srcgridsize] = ...
            patchlib.volknnsearch(noisyim, refim, patchSize, 'half', 'K', 10);
        
        qpatches = patchlib.patchmrf(patches, srcgridsize, pDst);
        resimg = patchlib.quilt(qpatches, srcgridsize, patchSize, 'half'); 
        
        patchview.figure();
        subplot(1, 3, 1); imagesc(noisyim); title('noisy (input) image');
        subplot(1, 3, 2); imagesc(refim); title('reference image');
        subplot(1, 3, 3); imagesc(resimg); title('top patch, half overlap result image');
    end
    
    if ismember(2, testids)
        
        % search for patches with a location difference weight as well
        [patches, pDst, pIdx, ~, srcgridsize, refgridsize] = ...
            patchlib.volknnsearch(noisyim, refim, patchSize , 'K', 10); % 'location', 0.001
                
        % quilt an image using the top patch
        resimg1 = patchlib.quilt(patches(:,:,1), srcgridsize, patchSize); 
        disp1 = patchlib.corresp2disp(srcgridsize, refgridsize, pIdx(:, 1), 'reshape', true);
        
        % run an mrf on overlap
        [qp, ~, ~, ~, pi] = patchlib.patchmrf(patches, srcgridsize, pDst, patchSize , ...
            'lambda_node', 0.1, 'lambda_edge', 100, 'pIdx', pIdx, 'refgridsize', refgridsize);
        disp2 = patchlib.corresp2disp(srcgridsize, refgridsize, pi, 'reshape', true);
        resimg2 = patchlib.quilt(qp, srcgridsize, patchSize); 
        
        % run an mrf on corresp
        usemex = exist('pdist2mex', 'file') == 3;
        edgefn = @(a1,a2,a3,a4) patchlib.correspdst(a1, a2, a3, a4, [], usemex); 
        [qp, ~, ~, ~, pi] = ...
            patchlib.patchmrf(patches, srcgridsize, pDst, patchSize , 'edgeDst', edgefn, ...
            'lambda_node', 0.1, 'lambda_edge', 100, 'pIdx', pIdx, 'refgridsize', refgridsize);
        disp3 = patchlib.corresp2disp(srcgridsize, refgridsize, pi, 'reshape', true);
        resimg3 = patchlib.quilt(qp, srcgridsize, patchSize); 
        
        % display results
        clim = [-max(size(refim)), max(size(refim))];
        patchview.figure();
        subplot(4, 3, 1); imagesc(noisyim); title('noisy (input) image'); axis off;
        subplot(4, 3, 2); imagesc(trueim); title('desired image'); axis off;
        subplot(4, 3, 3); imagesc(refim); title('reference image'); axis off;
        
        subplot(4, 3, 4); imagesc(resimg1); title('top patch, sliding overlap result'); axis off;
        subplot(4, 3, 5); imagesc(disp1{1}); title('disp x'); caxis(clim); colormap gray; axis off;
        subplot(4, 3, 6); imagesc(disp1{2}); title('disp y'); caxis(clim); axis off;
        
        subplot(4, 3, 7); imagesc(resimg2); title('overlap-based patchmrf result image'); axis off;
        subplot(4, 3, 8); imagesc(disp2{1}); title('disp x'); caxis(clim); axis off;
        subplot(4, 3, 9); imagesc(disp2{2}); title('disp y'); caxis(clim); axis off;
        
        subplot(4, 3, 10); imagesc(resimg3); title('correp-based patchmrf result image'); axis off;
        subplot(4, 3, 11); imagesc(disp3{1}); title('disp x'); caxis(clim); axis off;
        subplot(4, 3, 12); imagesc(disp3{2}); title('disp y'); caxis(clim); axis off;
    end
    
end


function [testids, refim, srcim, desiredim, patchSize] = setup(varargin)

    % decide on tests
    testids = ifelse(nargin == 0, '1:4', 'varargin{1}', true);
        
    % get noise standard deviation
    noisestd = ifelse(nargin < 2, '0.5', 'varargin{2}', true);
    
    [desiredim, srcim, refim] = example_prepareData('boston-pano-sunset', noisestd);
    patchSize = [5, 5, 3];
end
