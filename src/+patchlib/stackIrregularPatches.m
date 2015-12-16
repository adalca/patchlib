function [sparsePatchStack, entries] = stackIrregularPatches(locations, patches, volSize)
% create a sparse matrix of size [prod(volSize) x numel(reconPatches)] where the given patches are
% stacked according to subLocation. So, the matrix will have only one patch per column.
%
% patches is a cell array of patches. Some cell entries can be empty
% locations is a cell array of (top-left) locations for those patches
% volSize is the size of the volume for which a stack is build (NOT the size of the stack itself!)
%
% TODO: perhaps merge with stack() ?

    narginchk(3, 3);
    nPatches = numel(patches);
    
    % get available patches
    availidx = find(~cellfun(@isempty, patches));
    
    % initialize an index and value vector
    idxc = cell(numel(availidx), 1);
    valc = cell(numel(availidx), 1);
    
    % stack patches + stack weights where for each patch the weight is how far away from the edge
    % the voxel is
    for ii = 1:numel(availidx)
        i = availidx(ii);
        
        % compute the voxel range of this patch
        patchRange = arrayfunc(@(x, y) x : (x + y - 1), locations{i}, size(patches{i}));
        sub = ndgrid2cell(patchRange{:});
        sub = cellfunc(@(x) x(:), sub);
        
        % get the indices of the values in the sparse matrix
        idx = sub2ind(volSize, sub{:});
        idxc{ii} = [idx, repmat(i, [numel(idx), 1])]; 
        
        % append the values
        valc{ii} = patches{i}(:);
    end
    idxv = cat(1, idxc{:});
    valv = cat(1, valc{:});
    
    % build the sparse matrix
    sparsePatchStack = sparse(idxv(:, 1), idxv(:, 2), valv, prod(volSize), nPatches);

    % build sparse entry matrix
    entries = sparse(idxv(:, 1), idxv(:, 2), ones(size(valv)), prod(volSize), nPatches);