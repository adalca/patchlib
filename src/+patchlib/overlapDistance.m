function dst = overlapDistance(patches1, patches2, df21, varargin)
% OVERLAPDISTANCE distance of overlap between two patches
%   dst = overlapDistance(patches1, patches2, df21, patchSize, patchOverlap) computes distance of
%   overlap between two patches. Default distance is euclidean (L2). patches1 and patches2 are NxP
%   matrices, where P = prod(patchSize). N can be any number, usually 1 - N>1 is useful when, for
%   example, you have several 'candidate' patches for a particular location. df21 is the sign of the
%   second neighbor's location minus the first. patchOverlap is the usual patchOverlap used in
%   patchlib. The final distance is normalized by sqrt(#) where # is the number of overlapping
%   patches.
%
%   dst = overlapDistance(patches1, patches2, df21, precomp) allows for the specification of
%   precomputed overlaps in a n-dimentionsal struct, with 3 entries in each dimension, representing
%   df21 of -1, 0 and 1. Each entry should contain two fields: curIdx and neighborIdx. See
%   overlapRegionPrecomp for an example of how this is built.
%
%   dst = overlapDistance(patches1, patches2, df21, ..., useMex) allows the specification of useMex
%   boolean, indicating whether to use the pdist2mex() function instead of pdist2. This can only be
%   used if it's on the current path.
%
%   dst = overlapDistance(patches1, patches2, df21, ..., distance) allows for the specification of
%   the distance type (as taken by pdist2). Note you can still use useMex, but before distance
%
%   dst = overlapDistance(patches1, patches2, df21, ..., distance, distanceParameter) allows for the
%   specification of the distance type (as taken by pdist2), with, optinally, a parameter as
%   required by pdist2's use of that distance. Note you can still use useMex, but before distance
%
%   Author: Adrian Dalca

    % overlap regions
    if isstruct(varargin{1})
        precomp = varargin{1};
        varargin = varargin(2:end);
        cdf21 = num2cell(df21+2);
        pstr1idx = precomp(cdf21{:}).curIdx;
        pstr2idx = precomp(cdf21{:}).neighborIdx;
    
    else
        [pstr1idx, pstr2idx] = overlapRegions(varargin{1:2}, df21);
        varargin = varargin(3:end);
    end
    
    % decide if using mex
    useMex = false;
    isl = islogical(varargin{1});
    if isl
        useMex = varargin{1};
        varargin = varargin(2:end);
    end
    
    % prepare distance
    distance = ifelse(useMex, 'euc', 'euclidean');
    distancePar = {};
    if numel(varargin) > 0
        distance = varargin{1};
        if numel(varargin) > 1
            distancePar = varargin{2};
        end
    end

    % select overlapping parts of patches
    curPatches = patches1(:, pstr1idx(:));
    neighborPatches = patches2(:, pstr2idx(:));

    % get the distance, averaged by number of pixels
    if useMex
        dst = pdist2mex(curPatches', neighborPatches', distance, [distancePar{:}], [], []);
    else
        dst = pdist2(curPatches, neighborPatches, distance, distancePar{:});
    end
    dst = dst ./ sqrt(numel(pstr1idx));
end
