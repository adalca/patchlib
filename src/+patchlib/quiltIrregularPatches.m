function vol = quiltIrregularPatches(locations, patches, varargin)
% quilt (create a volume) out of irregularly placed patches
%
% patches is a cell array of patches. Some cell entries can be empty (we assume all-nan patch in that case.
% locations is a cell array of (top-left) locations for those patches
%
% TODO: perhaps merge with quilt?

    % input checking
    inputs = parseInputs(locations, patches, varargin{:});
        
    % build sparse stacks
    [patchStack, entries] = ...
        patchlib.stackIrregularPatches(locations, patches, inputs.volSize);
    stackNans = isnan(patchStack);
    entries(stackNans) = 0;
    patchStack(stackNans) = 0;
    
    % compute weight stack if necessary
    if ~isempty(inputs.weightPatches)   
        weightStack = patchlib.stackIrregularPatches(locations, inputs.weightPatches, inputs.volSize);
        weightStack(stackNans) = 0;
    end
    
    % compute final volume.
    if isempty(inputs.weightPatches)
        sm = sum(patchStack, 2) ./ sum(entries, 2);
    else
        sm = sum(weightStack .* patchStack, 2) ./ sum(weightStack, 2);
    end
    vol = reshape(full(sm), inputs.volSize);
end

function inputs = parseInputs(subLocation, reconPatches, varargin)

    narginchk(2, 6);

    p = inputParser();
    p.addRequired('subLocation', @iscell);
    p.addRequired('reconPatches', @iscell);
    p.addParameter('volSize', [], @isvector);
    p.addParameter('weightPatches', [], @isvector);
    p.parse(subLocation, reconPatches, varargin{:});
    inputs = p.Results;
    
    if isempty(inputs.volSize)
        c = cat(1, subLocation{:});
        inputs.volSize = max(c, [], 1);
    end
end