function disp2 = interpDisp(disp, patchSize, patchOverlap)
%INTERPDISP interpolate displacements given on a grid
%   disp2 = interpDisp(disp, patchSize, patchOverlap)
%
%   TODO: allow for 
%   disp2 = interpDisp(disp, idxsub)

    volSize = size(disp{1});

    % get subscripts
    [idxsub, ~, gridsize] = patchlib.grid(volSize, patchSize, patchOverlap, 'sub');
    assert(all(size(idxsub{1}) == gridsize));
    
    % get 
    xi = size2ndgrid(volSize);
    disp2 = cellfunc(@(x) interpn(idxsub{:}, x, xi{:}), disp);
    
end

