function dst = l2overlapdst(patches1, patches2, df21, patchSize, patchOverlap, nFeatures)

    narginchk(5, 6);
    if nargin == 5
        nFeatures = 1;
    end
    nDims = numel(patchSize);

    % for each dimension, do:
    %   grab the difference in that dimension
    %   if it's 1, then grab the last patchOverlap entries for the current patch and the first patchOverlap
    %       entries for the next patch, in this dimensions
    %   if it's -1, do the opposite
    %   if it's 0, get them all
    rangeCropCur = cell(nDims, 1);
    rangeCropNext = cell(nDims, 1);
    for d = 1:nDims
        switch df21(d)
            case 1
                rangeCropCur{d} = (patchSize(d) - patchOverlap(d) + 1):patchSize(d);
                rangeCropNext{d} = 1:patchOverlap(d);
            case -1
                rangeCropNext{d} = (patchSize(d) - patchOverlap(d) + 1):patchSize(d);
                rangeCropCur{d} = 1:patchOverlap(d);
            case 0 
                rangeCropNext{d} = 1:patchSize(d);
                rangeCropCur{d} = 1:patchSize(d);
            otherwise
                error('Unknown neighbors');
        end
    end

    % select the relevant indexes
    curIdx = patchCropIdx(patchSize, rangeCropCur, nFeatures);
    neighborIdx = patchCropIdx(patchSize, rangeCropNext, nFeatures);

    % select the relevant parts of the patches
    curPatches = patches1(:, curIdx(:));
    neighborPatches = patches2(:, neighborIdx(:));

    % get the distance, averaged by number of pixels
    dst = pdist2(curPatches, neighborPatches);
    dst = dst ./ sqrt(numel(curIdx));
end



function idx = patchCropIdx(patchSize, range, nFeatures)
   
    if nargin < 3, nFeatures = 1; end
    
    idx = false(patchSize);
    idx(range{:}) = true;
    idx = repmat(idx(:), [nFeatures, 1]);
        
%     % old method:
%     % patch idx in a patch-shaped matrix
%     patchIdxShape = reshape(1:prod(patchSize), patchSize); 
%     idx = patchIdxShape(rangeCropCur{:});
end
    
    