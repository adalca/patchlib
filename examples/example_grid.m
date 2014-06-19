function example_grid()

    pv = patchview;
    r = rand(11, 11);
    p = [5, 5];
    idx = patchlib.grid(size(r), p, -1, 'sub');
    pv.patchesInImage(r, p, [idx{1}(:), idx{2}(:)], 'top-left')
    
    r = rand(8, 8);
    idx = patchlib.grid(size(r), p, 2, 'sub');
    pv.patchesInImage(r, p, [idx{1}(:), idx{2}(:)], 'top-left')

