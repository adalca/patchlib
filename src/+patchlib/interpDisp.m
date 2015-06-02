function disp2 = interpDisp(disp, patchSize, patchOverlap, volSize, shift)
%INTERPDISP interpolate displacements given on a grid
%   disp2 = interpDisp(disp, patchSize, patchOverlap, volSize)
%   disp2 = interpDisp(disp, patchSize, patchOverlap, volSize, shift)
%
%   TODO: allow for 
%   disp2 = interpDisp(disp, idxsub)

    % get subscripts
    if exist('shift', 'var')
        [idxsub, ~, gridsize] = patchlib.grid(volSize, patchSize, patchOverlap, shift, 'sub');
    else
        [idxsub, ~, gridsize] = patchlib.grid(volSize, patchSize, patchOverlap, 'sub');
    end
    assert(all(size(idxsub{1}) == size(disp{1})));
    assert(all(size(idxsub{1}) == gridsize));
    
    
    % get the interpolated displacements. 
    xi = size2ndgrid(volSize);
    disp2 = cellfunc(@(x) interpn(idxsub{:}, x, xi{:}), disp);
    
end

