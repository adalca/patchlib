classdef patchlib < handle
    % PATCHLIB A library for working with n-d patches
    %   Currently still in development. 
    %
    %   Throughout the documentation, we'll use the following conventions:
    %       - we use the top left of a patch as the main point
    %       - grid: grid of patches that fit into a volume, using the top-left indexing scheme
    %       - V: number of voxels in a patch
    %       - N: number of elements in the grid, or prod(gridSize).
    %       - M: size along some dimension.
    %       - K: number of patches matching some criteria, e.g. when doing k-NN search
    %       - D: dimentionality
    %
    %   See readme.md for updates and function list.
    %
    %   ToAdd:
    %   - quilting
    %   - viewKNNSearch, using functions from viewPatchesInImage
    %   - view kNN patches (maybe with image?) with scores on top.
    %
    %   requires several functions from mgt (https://github.com/adalca/mgt)
    
    properties (Constant)
        default2DpatchSize = [5, 5];
        
        % group view functions
        view = struct('patchesInImage', @patchlib.viewPatchesInImage, ...
            'patchMatches2D', @patchlib.viewPatchMatches2D, ...
            'patches2D', @patchlib.viewPatches2D, ...
            'layers2D', @patchlib.viewLayers2D);
        
        % group test functions
        test = struct('viewPatchesInImage', @patchlib.testViewPatchesInImage, ...
            'viewPatchMatches2D', @patchlib.testViewPatchMatches2D, ...
            'grid', @patchlib.testGrid, ...
            'viewStackPatches', @patchlib.testStackPatches);

        figview = ifelse(exist('figuresc', 'file') == 2, @figuresc, @figure);
    end
    
    methods (Static)
        % library construction
        varargout = vol2lib(vol, patchSize, varargin);
        varargout = volStruct2lib(volStruct, patchSize, returnEffectiveLibrary);
        
        % quilting
        vol = quilt(patches, gridSize, varargin);
        
        % viewers
        varargout = viewPatchesInImage(im, patchSize, patchLoc, varargin)
        viewPatchMatches2D(origPatch, varargin);
        varargout = viewPatches2D(patches, patchSize, caxisrange, gridtype);
        viewLayers2D(layers, mode, varargin);
        viewPatchRef2D(vol, refs, vIdx, pIdx, rIdx, varargin);
        
        % testers
        testViewPatchesInImage(tid);
        testViewPatchMatches2D();
        testGrid();
        testStackPatches(varargin);
        testViewPatchRef2D(varargin);
        testPatchmrf(varargin);
        testQuilt(varargin);
        
        % main tools
        [idx, newVolSize, gridSize, overlap] = grid(volSize, patchSize, patchOverlap, varargin);
        [qpatches, bel, pot] = patchmrf(varargin);
        varargout = stackPatches(patches, patchSize, gridSize, varargin);
        [patches, pIdx, pDstIdx, pDst] = volknnsearch(src, refs, patchSize, varargin);
        
        % mini-tools
        dst = l2overlapdst(patches1, patches2, df21, patchSize, patchOverlap, nFeatures);
        patchSize = guessPatchSize(n, dim);
        patches = lib2patches(lib, pIdx, varargin)
        [gridSize, newVolSize] = patchcount(volSize, patchSize, patchOverlap, varargin)
        s = patchCenterDist(patchSize);
        overlap = overlapkind(str, patchSize);
        volSize = grid2volSize(gridSize, patchSize, varargin);
        [patchesCell, patchSize] = patchesmat2cell(patches, patchSize);
        rect = drawPatchRect(patchloc, patchSize, color);
        isv = isvalidoverlap(overlap);
    end
    
end
