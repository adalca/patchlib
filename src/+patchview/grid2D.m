function grid2D(gridIdx, vol)
    
    warning ('does not currently show the *size* of the patches, just their start');
    
    patchview.figure();
    
    imagesc(vol); colormap gray;
    
    [ysub, xsub] = ind2sub(size(vol), gridIdx);
    
    yuniq = sort(unique(ysub));
    astep = yuniq(2) - yuniq(1);
    yuniq = [yuniq; yuniq(end)+astep];
    
    xuniq = sort(unique(xsub));
    bstep = xuniq(2) - xuniq(1);
    xuniq = [xuniq; xuniq(end)+bstep];
    
    drawgrid(xuniq-0.5, yuniq-0.5, 'b');
    
    for i = 1:numel(gridIdx(:))
        y = ysub(i);
        x = xsub(i);
        hnd1 = text(x, y, sprintf('%d', gridIdx(i)));
        set(hnd1,'FontSize', 10, 'Color', 'r');
    end
