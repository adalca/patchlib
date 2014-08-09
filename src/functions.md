patchlib functions
==================

Main Functions
--------------
- [`patchlib.vol2lib`](src/@patchlib/vol2lib.m) transform a N-D volume into a patch library
- [`patchlib.volStruct2lib`](src/@patchlib/volStruct2lib.m) transform a volStruct into a patch library
- [`patchlib.grid`](src/@patchlib/grid.m) grid of patch starting points for N-D volume
- [`patchlib.stackPatches`](src/@patchlib/stackPatches.m) stack patches in layer structure
- [`patchlib.volknnsearch`](src/@patchlib/volknnsearch.m) k-NN search of patches in source given a set of reference volumes
- [`patchlib.patchmrf`](src/@patchlib/patchmrf.m) mrf patch inference on patch candidates on a grid
- [`patchlib.quilt`](src/@patchlib/quilt.m) quilt or reconstruct volume from patch indexes in library
- [`patchlib.gridsize`](src/@patchlib/gridsize.m) grid of patches that fit into a volume

Visualization
-------------
- [`patchview.patchesInImage`](src/@patchview/patchesInImage.m) visualize 2D patches in an image
- [`patchview.patchMatches2D`](src/@patchview/patchMatches2D.m) display 2D patches matching an original patch
- [`patchview.patches2D`](src/@patchview/patches2D.m) show 2D patches in a subplot grid
- [`patchview.layers2D`](src/@patchview/layers2D.m) view layers (as returned by patchlib.stackPatches)
- [`patchview.patchRef2D`](src/@patchview/patchRef2D.m)
- [`patchview.drawPatchRect`](src/@patchview/drawPatchRect.m)  draw rectangles in the current axis

Helpers
-------
- [`patchlib.overlapkind`](src/@patchlib/overlapkind.m) overlap amount to/from pre-specified overlap kind
- [`patchlib.guessPatchSize`](src/@patchlib/guessPatchSize.m) guess the size of a patch from nVoxels
- [`patchlib.patchCenterDist`](src/@patchlib/patchCenterDist.m) compute the distance to the center of a patch
- [`patchlib.grid2volSize`](src/@patchlib/grid2volSize.m) volume size from number of patches
- [`patchlib.isvalidoverlap`](src/@patchlib/isvalidoverlap.m) check overlap variable
- [`patchlib.grid2volSize`](src/@patchlib/grid2volSize.m) olume size from patch grid size
- [`patchlib.patchesmat2cell`](src/@patchlib/patchesmat2cell.m)
- [`patchlib.l2overlapdst`](src/@patchlib/l2overlapdst.m)
- [`patchlib.lib2patches`](src/@patchlib/lib2patches.m) (still in draft mode)

Under Construction
------------------
viewPatchNeighbors3D
