function [curIdx, neighborIdx] = overlapRegions(patchSize, varargin)
% OVERLAPREGIONS pairwise overlap regions of two neighboring patches
%   [curIdx, neighborIdx] = overlapRegions(patchSize, patchOverlap, df21) returns two logical
%   patches of size patchSize indicating the voxels where two neighbouring patches overlap.
%   patchOverlap is the standard patchOverlap used in patchlib. df21 is the sign of the location 
%   of the second patch with respect to the first --- it should be something like 
%   sign(locOfPatch2 - locOfPatch1). 
%
%   [curIdx, neighborIdx] = overlapRegions(patchSize, neighborOverlap) % TODO Allows for
%   specification of the second neighbor's overlap with the first - a vector the same size as
%   patchSize. A positive number means a the second patch comes after the first in that dimenion.
%   This version is not very well tested, but should be working fine.
%
% Contact: adalca.mit.edu

    narginchk(2, 3);
    if nargin == 2
        warning('overlapRegions with 2 parameters has not been thoroughly tested');
        [curIdx, neighborIdx] = overlapRegions(patchSize, neiOverlap, sign(neiOverlap));
        
    elseif nargin == 3
        patchOverlap = varargin{1};
        if ischar(patchOverlap)
            patchOverlap = patchlib.overlapkind(patchOverlap);
        end
        df21 = varargin{2};
        
        nDims = numel(patchSize);
        assert(all(df21 == 1 | df21 == 0 | df21 == -1));
        
        % for each dimension, do:
        %   grab the difference in that dimension
        %   if it's 1, grab the last patchOverlap entries for the current patch and the 
        %       first patchOverlap entries for the next patch, in this dimensions
        %   if it's -1, do the opposite
        %   if it's 0, get them all
        rangeCropCur = cell(nDims, 1);
        rangeCropNext = cell(nDims, 1);
        for d = 1:nDims
            switch df21(d)
                case 1
                    rangeCropCur{d} = (patchSize(d) - patchOverlap(d) + 1):patchSize(d);
                    rangeCropNext{d} = 1:patchOverlap(d);
                case -1
                    rangeCropCur{d} = 1:patchOverlap(d);
                    rangeCropNext{d} = (patchSize(d) - patchOverlap(d) + 1):patchSize(d);
                case 0
                    rangeCropNext{d} = 1:patchSize(d);
                    rangeCropCur{d} = 1:patchSize(d);
                otherwise
                    error('Unknown neighbors');
            end
        end
        
        % select the relevant indexes
        curIdx = patchCropIdx(patchSize, rangeCropCur);
        neighborIdx = patchCropIdx(patchSize, rangeCropNext); 
    end
end

function idx = patchCropIdx(patchSize, range)
    idx = false(patchSize);
    idx(range{:}) = true;
end
