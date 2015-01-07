function example_grid2D()
    sx = 30;
    sy = 20;
    
    v = rand(sx, sy);
    H = fspecial('gaussian',10,10);
    v = imfilter(v,H,'replicate');
    
    idx = patchlib.grid([sx, sy], [5, 5], 'half');
    patchview.grid2D(idx, v);
