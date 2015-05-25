patchlib functions
==================

Main Functions
--------------
- [`patchlib.vol2lib`](+patchlib/vol2lib.m) transform a N-D volume into a patch library
- [`patchlib.volStruct2lib`](+patchlib/volStruct2lib.m) transform a volStruct into a patch library
- [`patchlib.grid`](+patchlib/grid.m) grid of patch starting points for N-D volume
- [`patchlib.stackPatches`](+patchlib/stackPatches.m) stack patches in layer structure
- [`patchlib.volknnsearch`](+patchlib/volknnsearch.m) k-NN search of patches in source given a set of reference volumes
- [`patchlib.patchmrf`](+patchlib/patchmrf.m) mrf patch inference on patch candidates on a grid
- [`patchlib.quilt`](+patchlib/quilt.m) quilt or reconstruct volume from patch indexes in library
- [`patchlib.gridsize`](+patchlib/gridsize.m) grid of patches that fit into a volume

Visualization
-------------
- [`patchview.patchesInImage`](+patchview/patchesInImage.m) visualize 2D patches in an image
- [`patchview.patchMatches2D`](+patchview/patchMatches2D.m) display 2D patches matching an original patch
- [`patchview.patches2D`](+patchview/patches2D.m) show 2D patches in a subplot grid
- [`patchview.layers2D`](+patchview/layers2D.m) view layers (as returned by patchlib.stackPatches)
- [`patchview.patchRef2D`](+patchview/patchRef2D.m)
- [`patchview.grid2D`](+patchview/grid2D.m) visualize the patch grid on top of a volume.
- [`patchview.corresp2D`](+patchview/corresp2D.m) visualize correspondances in 2D
- [`patchview.drawPatchRect`](+patchview/drawPatchRect.m)  draw rectangles in the current axis
- [`patchview.patch3D`](+patchview/patch3D.m) visualize a 3D patch
- [`patchview.votehist`](+patchview/votehist.m) see histograms of the votes for locations (interactive)

Helpers
-------
- [`patchlib.overlapkind`](+patchlib/overlapkind.m) overlap amount to/from pre-specified overlap kind
- [`patchlib.guessPatchSize`](+patchlib/guessPatchSize.m) guess the size of a patch from nVoxels
- [`patchlib.patchCenterDist`](+patchlib/patchCenterDist.m) compute the distance to the center of a patch
- [`patchlib.grid2volSize`](+patchlib/grid2volSize.m) volume size from number of patches
- [`patchlib.isvalidoverlap`](+patchlib/isvalidoverlap.m) check overlap variable
- [`patchlib.grid2volSize`](+patchlib/grid2volSize.m) volume size from patch grid size
- [`patchlib.corresp2disp`](+patchlib/corresp2disp.m) transform locations to displacement.
- [`patchlib.interpDisp`](+patchlib/interpDisp.m) interpolate displacement.
- [`patchlib.patchesmat2cell`](+patchlib/patchesmat2cell.m)
- [`patchlib.l2overlapdst`](+patchlib/l2overlapdst.m)
- [`patchlib.lib2patches`](+patchlib/lib2patches.m) (still in draft mode)
- ['patchlib.locvotes'](+patchlib/locvotes.m) votes given volume location

corresp2disp

Under Construction
------------------
viewPatchNeighbors3D
