function disp2 = interpDisp(disp, patchSize, patchOverlap, volSize, shift)
%INTERPDISP interpolate displacements given on a grid
%   disp2 = interpDisp(disp, patchSize, patchOverlap, volSize)
%   disp2 = interpDisp(disp, patchSize, patchOverlap, volSize, shift) startdelta should be
%       (patchsize - 1) / 2 in most cases, e.g. shift to get the centers
%
%   TODO: allow for 
%   disp2 = interpDisp(disp, idxsub)

    % get subscripts
    [idxsub, ~, gridsize] = patchlib.grid(volSize, patchSize, patchOverlap, 'sub');
    
    if nargin <= 4
        shift = volSize(:) * 0;
    end
    
    idxsub = cellfunc(@(x, y) x + y, idxsub, mat2cellsplit(shift(:)));
    assert(all(size(idxsub{1}) == size(disp{1})));
    assert((prod(gridsize) == 1 && numel(idxsub{1})) || all(size(idxsub{1}) == gridsize));
    
    % get the interpolated displacements. 
    xi = size2ndgrid(volSize);
    disp2 = cellfunc(@(x) interpn(idxsub{:}, x, xi{:}), disp);
    
end

