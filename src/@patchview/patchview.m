classdef patchview < handle
    % PATCHVIEW A visualization library for patchlib
    %   Currently still in development. 
    %
    %   Throughout the documentation, we'll use the same conventions as in patchlib
    %
    %   - viewKNNSearch, using functions from viewPatchesInImage
    %   - view kNN patches (maybe with image?) with scores on top.
    %
    %   requires several functions from mgt (https://github.com/adalca/mgt)
    
    properties (Constant)
        
      
        figure = ifelse(exist('figuresc', 'file') == 2, @figuresc, @figure); %#ok<REDEF>
    end
    
    methods (Static)
       
        % viewers
        varargout = patchesInImage(im, patchSize, patchLoc, varargin)
        patchMatches2D(origPatch, varargin);
        varargout = patches2D(patches, patchSize, caxisrange, gridtype);
        layers2D(layers, mode, varargin);
        patchRef2D(vol, refs, vIdx, pIdx, rIdx, varargin);
        rect = drawPatchRect(patchloc, patchSize, color);
        grid2D(gridIdx, vol);
        colmap = corresp2D(pIdx, refgridsize, srcgridsize, varargin);
        patch3D(patch, range, varargin);
    end
    
end
