function [lib, newSize] = mrfVol2lib(vol, patchSize, varargin)
% TODO - combine this with vol2lib with mrf option? Also, option to just specify starting idx-es?
%   'MRF' is really just controlling overlap of patches. Overlap should be <= (patchSize-1). 
% MRFVOL2LIB - vol 2 library on an mrf grid (i.e. only patches that start on the mrf grid points)
%   lib = mrfVol2lib(vol, patchSize) - cut volume to the next-smallest size that matches 
%       the necessary size given that patches start on the mrf grid, i.e. 0.5*(p+1)*N + 0.5*(p-1)
%       then prepare the appropriate volume
%
%   lib = mrfVol2lib(vol, patchSize, shiftStart, shiftInterpMode) - also perform
%       a shift of the volume by shiftStart amount (1 x nDims, can be
%       non-integer value) via given interpolation mode
%
%   lib = mrfVol2lib(vol, patchSize, nMiddleVoxels) - include a 1 x nDims vector of the number of
%       voxels in the 'middle' of the patch.
%
%   lib = mrfVol2lib(vol, patchSize, shiftStart, shiftInterpMode, nMiddleVoxels) - combination of
%       other two runs
%
% todo: find a way to build the library only for mrf starting-points directly. Currently, the whole
% lib is built and the mrf-starting patches selected and returned

    narginchk(2, 5);

    % get number of middle voxels
    if nargin == 3 || nargin == 5
        nMiddleVoxels = varargin{end};
    else
        nMiddleVoxels = ones(1, numel(patchSize));
    end
    
    % shift volume if necessary
    if nargin >= 4
        shiftStart = varargin{1};
        shiftInterpMode = varargin{2};
        vol = shiftVol(vol, shiftStart, shiftInterpMode);
    end
    
    % compute appropriate size
    [nPatches, ~] = volSize2nPatches(size(vol), patchSize, nMiddleVoxels);
    newSize = nPatches2volSize(nPatches, patchSize, nMiddleVoxels);
%     nPatches = floor((size(vol) - ((patchSize - 1)/2))./((patchSize + 1)/2));
%     newSize = ((patchSize + 1)/2) .* nPatches + ((patchSize - 1)/2);

    % crop volume
    vol = actionSubArray('extract', vol, ones(1, ndims(vol)), newSize);
    
    % extract full library
    lib = vol2lib(vol, patchSize);
    
    % get the mrf grid
    % TODO: seems like we need to assume mrf grid that's not 1-voxel centered
    idx = mrfGridIdx(size(vol), patchSize, [], nMiddleVoxels);
    
    % extract grid points to return
    lib = lib(idx, :);
end
