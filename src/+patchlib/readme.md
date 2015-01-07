patchlib
========
A library for working with n-d patches.
Currently still in development. 

Throughout the documentation, we'll use the following conventions:
  - we use the top left of a patch as the main point
  - grid: grid of patches that fit into a volume, using the top-left indexing scheme
  - V: number of voxels in a patch
  - N: number of elements in the grid, or prod(gridSize).
  - M: size along some dimension.
  - K: number of patches matching some criteria, e.g. when doing k-NN search
  - D: dimentionality

See readme.md for updates and function list.

ToAdd
-----
  - viewKNNSearch, using functions from viewPatchesInImage
  - view kNN patches (maybe with image?) with scores on top.

requires several functions from mgt (https://github.com/adalca/mgt)
