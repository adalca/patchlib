function [qpatches, varargout] = patchmrf(varargin)
% PATCHMRF mrf patch inference on patch candidates on a grid
%   qpatches = patchmrf(patches, gridSize, patchDst) perform mrf inference on patch candidates on a
%   grid. patches is either a NxK cell of formatted patches, or a NxVxK array, gridSize is a 1xD
%   vector with prod(gridSize) == N, and patchDst is a NxK array of the individual patch
%   distances/costs.
%
%   The function computes potential out of unary and edge distances via exp(-lambda_x * dst), and
%   then sets up an MRF. it performs inference via LBP using UGM_Infer_LBP. It then returns the
%   patches with the highest posterior at every point on the grid.
%
%   qpatches = patchmrf(..., patchSize) allows for the specification of the 1xD patchSize. if this
%   is not provided, it will be guessed from the patches.
%
%   qpatches = patchmrf(..., patchSize, patchOverlap) allows for the specification of patchOverlap
%   (1xD array or char). If this is not specified, 'sliding' is assumed - see patchlib.overlapkind for
%   more information on options.
%
%   qpatches = patchmrf(..., Param, Value, ...) allows for the specification of several options:
%       edgeDst: (default: @patchlib.l2overlapdst) function handle of the edge function, i.e.
%       functino to compute the distance between two neighbouring patches. The arguments passed are
%       fun(pstr1, pstr2, df21, inputs), see l2overlapdst below for an example.
%           pstr are struct with fields: patches, loc, disp, ref
%
%       lambda_node: (default: 1) the value for lambda_node in pot_node = exp(-lambda_node * dst).
%       lambda_edge: (default: 1) the value for lambda_edge.
%       maxLBPIters: (default: 100). the maximum number of LBP iterations. 
%       pIdx
%       refgridsize
%
%   [qpatches, bel, pot, qSel, pIdxSel, rIdxSel] = patchmrf(...). see qSel use in code.
%
% Requires: UGM toolbox
%
% See Also: overlapkind, grid
%
% Contact: adalca@csail

    % parse inputs
    [patches, gridSize, pDst, inputs] = parseinputs(varargin{:});
    if nargout >= 4
        assert(~isempty(inputs.pIdx), 'if asking for pIdxSel, need pIdx input');
    end
    
    % Node potentials. Should be nNodes x nStates;
    nodePot = exp(-inputs.lambda_node * pDst);

    % Edge potentials.
    [edgePot, edgeStruct] = prepEdgePot(patches, gridSize, inputs);
    
    % run Loopy BP via UGM
    [nodeBel, edgeBel, logZ] = UGM_Infer_LBP(nodePot, edgePot, edgeStruct);
    assert(isclean(nodeBel), 'PATCHLIB:PATCHMRF', 'UGMLBP: Bad nodeBel.');
        
    % extract max nodes
    [~, maxNodes] = max(nodeBel, [], 2);
    
    % create index in pDst - sized array
    qSel = sub2ind(size(pDst), (1:size(pDst, 1))', maxNodes(:));
    permpatches = permute(patches, [2, 1, 3]); % each row is a voxel
    qpatches = permpatches(:, qSel)'; % for each voxel, use the selection
    pIdxSel = []; rIdxSel = [];
    if nargout >= 4 && ~isempty(inputs.pIdx)
        pIdxSel = inputs.pIdx(qSel);
        rIdxSel = inputs.rIdx(qSel);
    end
    
    % prepare outputs
    belstruct = structrich(nodeBel, edgeBel, logZ, maxNodes);
    potstruct = structrich(nodePot, edgePot, edgeStruct);
    vargout = {belstruct, potstruct, qSel, pIdxSel, rIdxSel};
    varargout = vargout(1:nargout);
end



function [edgePot, edgeStruct] = prepEdgePot(patches, gridSize, inputs)
% prepare edge potential
    
    patchesperm = permute(patches, [3, 2, 1]);
    
    
    % prepare the 'sub vector' of each location
    siz = ifelse(isempty(inputs.srcSize), gridSize, inputs.srcSize);
    locSub = ind2subvec(siz, inputs.gridIdx(:));
    
    % build correspondances vector
    dispSubperm = [];
    if ~isempty(inputs.pIdx)
        idx = permute(inputs.pIdx, [1, 3, 2]);
        dispSub = patchlib.corresp2disp(siz, inputs.refgridsize, idx, inputs.rIdx, 'srcGridIdx', inputs.gridIdx);
        dispSub = cat(2, dispSub{:});
        dispSubperm = permute(dispSub, [3, 2, 1]); % will use the permutation version
    end
    
    % precomputation of overlap regions
    olregions = patchlib.overlapRegionsPrecomp(inputs.patchSize, inputs.patchOverlap);
    
    % create edge structure - should be the right size
    adj = vol2adjacency(gridSize, inputs.connectivity);
    nStates = size(patches, 3);
    edgeStruct = UGM_makeEdgeStruct(adj, nStates , true, inputs.maxLBPIters);
    
    % compute distances. 
    % TODO: this computation is doubled for no reason :(
    %#ok<*PFBNS>
    edgePot = zeros(nStates, nStates, edgeStruct.nEdges);
    edgeEnds = edgeStruct.edgeEnds;
%     par
    for e = 1:edgeStruct.nEdges
        locedgeEnds = edgeEnds(e, :);
        n1 = locedgeEnds(1);
        n2 = locedgeEnds(2);
        
        % extract the patches for these two node
        patches1 = patchesperm(:, :, n1);
        patches2 = patchesperm(:, :, n2);
        
        % prepare structs
        pstr1 = struct('patches', patches1, 'loc', locSub(n1, :));
        pstr2 = struct('patches', patches2, 'loc', locSub(n2, :));
       
        % add displacement and reference
        % TODO: add pIdx(n1, :) ?
        if ~isempty(inputs.pIdx)
            pstr1.disp = dispSubperm(:, :, n1); 
            pstr1.ref = inputs.rIdx(n1, :); 
            pstr2.disp = dispSubperm(:, :, n2); 
            pstr2.ref = inputs.rIdx(n2, :);
        end
            
        % get the distance.
        dst = inputs.edgeDst(pstr1, pstr2, olregions, inputs);
        edgePot(:, :, e) = exp(-inputs.lambda_edge * dst);
    end
end



function [patches, gridSize, dst, inputs] = parseinputs(varargin)
% parse inputs

    % break down varargin in first inputs and param/value inputs.
    narginchk(3, inf);
    strloc = find(cellfun(@ischar, varargin), 1, 'first');
    if numel(strloc) == 0
        mainargs = varargin;
        paramvalues = {};
    else
        assert(numel(strloc) == 1);
        if isodd(numel(varargin(strloc:end))) % patchOverlap is last main argument, in char form
            mainargs = varargin(1:strloc);
            paramvalues = varargin((strloc+1):end);
        else
            mainargs = varargin(1:(strloc-1));
            paramvalues = varargin(strloc:end);
        end
    end
        
    % parse first part of inputs
    assert(numel(mainargs) >= 3 && numel(mainargs) <= 5);
    patches = mainargs{1};
    gridSize = mainargs{2};
    dst = mainargs{3};
    if numel(mainargs) >= 4
        patchSize = mainargs{4};
    end
    
    if numel(mainargs) == 5
        patchOverlap = mainargs{5};
    end

    % prepare patches in array form
    if iscell(patches)
        if ~exist('patchSize', 'var')
            patchSize = size(patches{1});
        end

        % transform the patches from cell to large matrix
        patchesm = zeros([size(patches, 1), prod(patchSize), size(patches, 2)]);
        for i = 1:size(patches, 1);
            for j = 1:size(patches, 2);
                patchesm(i, :, j) = patches{i, j}(:);
            end
        end
        patches = patchesm;
        
    else
        if ~exist('patchSize', 'var')
            patchSize = patchlib.guessPatchSize(size(patches, 2));
        end
    end

    % some checks. Patches should be NxVxK now, dst should be NxK, where N == prod(gridSize);
    assert(size(patches, 1) == size(dst, 1), 'Patches should be NxVxK now, dst should be NxK');
    assert(size(patches, 3) == size(dst, 2), 'Patches should be NxVxK now, dst should be NxK');
    assert(size(patches, 1) == prod(gridSize));
    
    % get patch overlap
    if ~exist('patchOverlap', 'var')
        patchOverlap = 'sliding';
        warning('Using Default sliding overlap');
    end  
    if ischar(patchOverlap)
        patchOverlap = patchlib.overlapkind(patchOverlap, patchSize);
    end
    
    % parse the rest of the inputs
    p = inputParser();
    p.addParameter('edgeDst', @l2overlapdst, @isfunc);
    p.addParameter('lambda_node', 1, @isnumeric);
    p.addParameter('lambda_edge', 1, @isnumeric);
    p.addParameter('maxLBPIters', 100, @isnumeric);
    p.addParameter('pIdx', [], @isnumeric);
    p.addParameter('rIdx', [], @isnumeric);
    p.addParameter('refgridsize', [], @(x) isnumeric(x) || iscell(x));
    p.addParameter('gridIdx', 1:prod(gridSize), @isnumeric);
    p.addParameter('srcSize', [], @isnumeric);
    p.addParameter('connectivity', numel(gridSize)^3-1, @isnumeric);
    p.parse(paramvalues{:})
    inputs = p.Results;
    
    inputs.patchSize = patchSize;
    inputs.patchOverlap = patchOverlap;
    
    % use correspondances if both refgridsize and pIdx are passed in.
    inputs.useCorresp = false;
    if ~isempty(inputs.pIdx) && ~isempty(inputs.refgridsize)
        inputs.useCorresp = true;
    end
    
    if ~isempty(inputs.pIdx) && ismember('rIdx', p.UsingDefaults)
    	inputs.rIdx = ones(size(inputs.pIdx));
    end
    
    inputs.useMex = exist('pdist2mex', 'file') == 3;
end


function dst = l2overlapdst(pstr1, pstr2, precomp, inputs)
    df21 = sign(pstr2.loc - pstr1.loc);
    dst = patchlib.overlapDistance(pstr1.patches, pstr2.patches, df21, precomp, inputs.useMex);
end