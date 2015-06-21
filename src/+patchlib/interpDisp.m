function disp2 = interpDisp(disp, patchSize, patchOverlap, volSize, startDel)
%INTERPDISP interpolate displacements given on a grid
%   disp2 = interpDisp(disp, patchSize, patchOverlap, volSize)
%   disp2 = interpDisp(disp, patchSize, patchOverlap, volSize, startDel) startDel should be
%       (patchsize + 1) / 2 in most cases, e.g. to get the centers
%
%   TODO: allow for 
%   disp2 = interpDisp(disp, idxsub)

    % get subscripts
    if exist('startDel', 'var')
        [idxsub, ~, gridsize] = patchlib.grid(volSize, patchSize, patchOverlap, startDel, 'sub');
    else
        [idxsub, ~, gridsize] = patchlib.grid(volSize, patchSize, patchOverlap, 'sub');
    end
    assert(all(size(idxsub{1}) == size(disp{1})));
    assert((prod(gridsize) == 1 && numel(idxsub{1})) || all(size(idxsub{1}) == gridsize));
    
    
    % get the interpolated displacements. 
    xi = size2ndgrid(volSize);
    disp2 = cellfunc(@(x) interpn(idxsub{:}, x, xi{:}), disp);
    
end

