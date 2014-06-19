function example_viewPatchesInImage(testid)
% test patch viewing methods.
%   testid can be a vector of all the desired test. 
%       1 - simple test showing several patches in a peppers image
%       2 - interactive test. If running this test, the image in test 1 will close.
%       3 - interactive kNN search test. First, select a patch on the interactive window, then close
%           the window - the patch will be caught and a knn Search will be done
%

    if nargin == 0
        testid = 1;
    end
    
    im = imresize(im2double(imread('peppers.png')), [75, 75]);
    pv = patchview;
    patchLoc = [7, 7; 25, 23; 17, 29; 37, 13; 10, 10];
    patchSize = [7, 7];
    
    if ismember(1, testid)
        % take a look at patches in the image
        pv.patchesInImage(im, patchSize, patchLoc);
        pause(1);
    end
    
    if ismember(2, testid)
        % take a look at patches in the image, interactively
        patches = pv.patchesInImage(im, patchSize, patchLoc, true);
        fprintf('Returned %d patches\n', numel(patches));
    end
    
    if ismember(3, testid)
        
        % extract the patch
        patches = pv.patchesInImage(im, patchSize, [], true);
        if numel(patches) > 1
            warning('You selected more than one patch. Using First Patch Only');
        end
        
        % build image library. Adding 3 to patchSize to allow for color to work.
        [lib, libidx] = patchlib.vol2lib(im, [patchSize, 3]);
        
        % do knn search for first 9 matches
        pIdx = knnsearch(lib, patches(1).vol(:)', 'K', 9);
        
        % get the location
        linidxnn = libidx(pIdx);
        [x, y, z] = ind2sub(size(im), linidxnn);
        assert(all(z == 1), 'z should be all 1s since there''s no actual depth');
        
        % show result
        pv.patchesInImage(im, patchSize, [x, y]);
    end
