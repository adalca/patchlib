function patchMatches2D(origPatch, varargin)
% VIEWPATCHMATCHES display 2D patches matching an original patch
%   viewPatchMatches(origPatch, matchPatches) display an original 2D patch and several
%       other ('matching') patches. origPatch is a [1 x nPixels] vector of the original patch, with
%       nPixels the number of pixels in the patch is the number of pixes in a patch. matchPatches is
%       a [nMatches x nPixels] matrix with nMatches matching pixels. The visualization will then
%       show the original patch on the left subplot, and the matching patches in the right of that.
%   
%       Alternatively, origPatch can be [nOrigPatches x nPixels], i.e. several original patches. In 
%       that case, matchPatches should be a cell array of nOrigPatches [nMatches x nPixels] matrices
%       indicating the appropriate matching patches for each origPatch. (E.g. origPatch(3, :) has
%       corresponding matching patches matchPatches{3}). 
%
%       Alternatively, all arguments could be passed as already-formatted patches. In this case,
%       origPatch is a N x 1 cell, with each entry a patch (e.g. 5x5). Further, matchParches is a 
%       M x N cell, where M is the number of matches and N is nOrigPatches, the number of original
%       patches, or comparisons. Each cell is then a patch image.
%
%   viewPatchMatches(origPatch, matchPatches, corrPatches1, ...) allows the specification
%        of more corresponding patches (e.g. corrPatches1 could be the equivalent labeled patches).
%        corrPatchesX should be the same form as matchPatches. 
%   
%   viewPatchMatches(..., ParamName, ParamValue, ...) allows for optional inputs:
%       caxis - a cell of [1x2] coloraxis vector, or [Mx1] cell of coloraxis vectors
%       patchSize - the patchSize, e.g. [5, 5]. Automatic detection is attempted if row-wise patches
%       are provided and patchSize is not provided. 
%
%   % TODO: plot/compute distances/etc
%
% Contact: adalca@csail.mit.edu

    % parse param/value inputs
    [origPatch, matchgroups, inputs] = parseinputs(origPatch, varargin{:});
    nPatches = numel(origPatch);
    nMatchGroups = numel(matchgroups);
    nMatches = size(matchgroups{1}, 1);
    
    % create the main figure
    patchview.figure();
    
    % compute the number of rows and columns in the plot
    nRows = nPatches * nMatchGroups;
    nCols = nMatches + 1;
    
    % go through all the patches
    for i = 1:nPatches
        
        % display original patch
        subplot(nRows, nCols, nCols * ((i - 1) * nMatchGroups) + 1);
        imshow(origPatch{i});
        caxis(inputs.caxis{1});
        title('original');
        
        % compute vertical subplot delay
        groupsDelay = nCols * ((i - 1) * nMatchGroups) + 1;
        
        % display knn Patches from the extra groups.
        for t = 1:nMatchGroups
            for j = 1:nMatches
                kp = matchgroups{t}{j, i};
                idx = groupsDelay + nCols * (t-1) + j;
                subplot(nRows, nCols, idx);
                imshow(kp);
                caxis(inputs.caxis{1 + t});
            end
        end
    end
end
    
function [origPatch, matchgroups, inputs] = parseinputs(origPatch, varargin)
% process input parser

    f = find(cellfun(@ischar, varargin), 1, 'first');
    args = varargin(f:end);
    
    % parse param/value args
    p = inputParser();
    p.addParamValue('caxis', {[0, 1]});
    p.addParamValue('patchSize', []);
    p.parse(args{:});
    inputs = p.Results;
    
    % check caxis
    if ~iscell(inputs.caxis)
        inputs.caxis = {inputs.caxis};
    end
        
    % determine the number of matching groups
    if ~isempty(f)
        matchgroups = varargin(1:(f-1));
    else
        matchgroups = varargin;
    end
    nMatchGroups = numel(matchgroups);
    
    if numel(inputs.caxis) == 1
        inputs.caxis(2:(1+numel(matchgroups))) = inputs.caxis(1);
    end
    
    
    % inputs could be:
    % 1) orig N x nVoxels, 
    %    matchesX is Nx1 cell with each entry being M x nVoxels
    %
    % 2) orig is Nx1 cell, each entry is a volume
    %    matchesX is cell of M x N, each entry is a volume
    
    % transform matrix entries to cell-based entries
    if ~iscell(origPatch)
        nPatches = size(origPatch, 1);
        if isempty(inputs.patchSize)
            inputs.patchSize = patchlib.guessPatchSize(size(origPatch, 2), 2);
        end
        
        op = cell(nPatches, 1);
        mg = cell(nMatchGroups, 1);
        for m = 1:nMatchGroups
            if ~iscell(matchgroups{m})
                matchgroups{m} = matchgroups(m);
            end
            nMatches = size(matchgroups{m}{1}, 1);
            mg{m} = cell(nMatches, nPatches);
        end
        
        for i = 1:nPatches
            op{i} = reshape(origPatch(i, :), inputs.patchSize); 
            
            for m = 1:nMatchGroups
                for n = 1:nMatches
                    mg{m}{n, i} = reshape(matchgroups{m}{i}(n, :), inputs.patchSize);
                end
            end
        end
        
        origPatch = op;
        matchgroups = mg;
    end
end   
