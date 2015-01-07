function dst = patchCenterDist(volSize)
% PATCHCENTERDIST distance from the center of the volume at every voxel
%   dst = patchCenterDist(volSize) distance from the center of the volume at every voxel. dst is
%   a volume of size volSize, (any dimension).
%
% Example for 2D:
%   imagesc(patchlib.patchCenterDist([128, 192]));
%
% See Also: volCenterDist();
%
% Contact: adalca@csail.mit.edu

    dst = volCenterDist(volSize);
