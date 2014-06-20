patchlib
========

A library for working with N-D patches, currently very much in development.

Please let us know of any questions/suggestions at adalca@csail.mit.edu

Main Functions
--------------
- [`patchlib.vol2lib`](vol2lib.m) transform a N-D volume into a patch library
- [`patchlib.volStruct2lib`](volStruct2lib.m) transform a volStruct into a patch library
- [`patchlib.grid`](grid.m) grid of patch starting points for N-D volume
- [`patchlib.stackPatches`](stackPatches.m) stack patches in layer structure
- [`patchlib.volknnsearch`](volknnsearch.m) k-NN search of patches in source given a set of reference volumes
- [`patchlib.patchmrf`](src/@patchlib/patchmrf.m) 
- [`patchlib.quilt`](src/@patchlib/quilt.m)

Helpers
-------
- [`patchlib.gridsize`](gridsize.m) grid of patches that fit into a volume
- [`patchlib.lib2patches`](lib2patches.m) (still in draft mode)
- [`patchlib.overlapkind`](overlapkind.m) overlap amount to/from pre-specified overlap kind
- [`patchlib.guessPatchSize`](guessPatchSize.m) guess the size of a patch from nVoxels
- [`patchlib.patchCenterDist`](patchCenterDist.m) compute the distance to the center of a patch
- [`patchlib.gridsize2volSize`](gridsize2volSize.m) volume size from number of patches
- [`patchlib.isvalidoverlap`](isvalidoverlap.m) check overlap variable
- [`patchlib.drawPatchRect`](drawPatchRect.m) draw rectangles in the current axis
- [`patchlib.grid2volSize`](src/@patchlib/grid2volSize.m) 
- [`patchlib.l2overlapdst`](src/@patchlib/l2overlapdst.m)
- [`patchlib.patchesmat2cell`](src/@patchlib/patchesmat2cell.m)

Examples
--------
- [`example_viewPatchesInImage`](testViewPatchesInImage.m) test view.patchesInImage
- [`example_viewPatchMatches2D`](testViewPatchMatches2D.m) test view.patchMatches2D
- [`example_grid`](testGrid.m) test grid
- [`example_stackPatches`](testStackPatches.m) Test stackPatches on simple reconstruction task.

Visualization
-------------
- [`patchview.patchesInImage`](viewPatchesInImage.m) visualize 2D patches in an image
- [`patchview.patchMatches2D`](viewPatchMatches2D.m) display 2D patches matching an original patch
- [`patchview.patches2D`](viewPatches2D.m) show 2D patches in a subplot grid
- [`patchview.layers2D`](viewLayers2D.m) view layers (as returned by patchlib.stackPatches)

Under Construction
------------------
viewPatchNeighbors3D
