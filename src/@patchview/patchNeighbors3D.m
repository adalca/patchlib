function patchNeighbors3D(curIdx, rangeCropCur, neighborIdx, rangeCropNext, hrPatchSize, nFeatures, dIdx, n1, n2, patches1, patches2, dst, p1extract, p2extract)
%
%
%   TODO: 
%       + clean up the function and understand the inputs
%       + add all slices of a 3D image 
    
%     p1extract = 1;
%     p2extract = 2;

    curIdxr = reshape(curIdx, [hrPatchSize, nFeatures]);
    neighborIdxr = reshape(neighborIdx, [hrPatchSize, nFeatures]);
    
    % extract top patches
    % TODO: extract the specific part of the patches that are given in ranges
    % and re-size appropriately
    p1 = patches1(p1extract, curIdx(:));
    for i = 1:3, sz(i) = numel(rangeCropCur{i}); end
    p1r = reshape(p1, [sz, nFeatures]);
    p2 = patches2(p2extract, neighborIdxr(:));
    for i = 1:3, sz(i) = numel(rangeCropNext{i}); end
    p2r = reshape(p2, [sz, nFeatures]);
    az = 45;
    el = 45;
    axisLim = [0.5, hrPatchSize(1)+0.5, 0.5, hrPatchSize(2)+0.5, 0.5, hrPatchSize(3)+0.5];
    g = gray(256);
    g(1, :) = 1;
    
    % plot
    figure(1);
    clf;
    
    subplot(2,2,1);
    title('Edge Mask (N1)');
    curMat = permute(curIdxr(:,:,:,1), [1, 3, 2]);
    PATCH_3Darray(curMat, [0.5, 0.5, 0.5]);
    annotatePlot(axisLim, az, el);
    
    subplot(2,2,2);
    title('Edge Mask (N2)');
    neiMat = permute(neighborIdxr(:,:,:,1), [1, 3, 2]);
    PATCH_3Darray(neiMat, [0.5, 0.5, 0.5]);
    annotatePlot(axisLim, az, el);
    
    % show some patches
    subplot(2,2,3);
    title('Edge Values (N1)');
    p1Mat = permute(p1r(:,:,:,1), [1, 3, 2]);
    PATCH_3Darray(p1Mat, rangeCropCur{1}, rangeCropCur{3}, rangeCropCur{2}, g, 'col');
    annotatePlot(axisLim, az, el);
    
    subplot(2,2,4);
    title('Edge Values (N2)');
    p2Mat = permute(p2r(:,:,:,1), [1, 3, 2]);
    PATCH_3Darray(p2Mat, rangeCropNext{1}, rangeCropNext{3}, rangeCropNext{2}, g, 'col');
    annotatePlot(axisLim, az, el);
    
    
    % compute ids
    for i = 1:3
        n1sub(i) = dIdx{i}(n1);
        n2sub(i) = dIdx{i}(n2);
    end
    
    titl = ['[', num2str(n1sub), '] [', num2str(n2sub), '] dst:', num2str(dst(p1extract, p2extract))];
    
    mtit(titl);
end


function annotatePlot(axisLim, az, el)
    axis(axisLim);
    ylabel('time');
    xlabel('X');   
    zlabel('Y');
    view(az, el);
end

