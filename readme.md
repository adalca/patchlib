patchlib
========

A powerful library for working with N-D patches (currently very much in development). The library also includes several 2D and 3D examples to illustrate the library applicability.

- See [`functions`](src/functions.md) for a list of functions in this library.
- See [`examples`](examples/examples.md) for a list of examples to get you started.


Installation
-------

#### Set up code
Do a git pull or download patchlib as a zip. Unzip the files, and add the folder to your MATLAB path:  
`>> addpath(genpath('PATH_TO_PATCHLIB'));`

Then run setup script:  
`>> verifypatchlib.m;`

#### Dependencies
You'll need some dependencies, based on which code you want to run. Add each toolbox to your MATLAB path.

The following two toolboxes are required by all of the code:
- [mgt](https://github.com/adalca/mgt)
- [mvit](https://github.com/adalca/mivt)

The MRF-related methods (e.g. for spatial regularization):
- [UGM library by Mark Schmidt](http://www.cs.ubc.ca/~schmidtm/Software/UGM.html)



Contributors
------------
Adrian Dalca ([web](http://adalca.mit.edu) | [email](mailto:adalca@mit.edu))  
Katie Bouman ([web](http://people.csail.mit.edu/klbouman) | [email](mailto:klbouman@csail.mit.edu))

**Contact** Please let us know of any questions/suggestions: {adalca,klbouman}@csail.mit.edu

Citation
--------
If you find this library useful, please cite:  
A.V. Dalca, K.L. Bouman, W.T. Freeman, M.R. Sabuncu, N.S. Rost, P. Golland. Population Based Image Imputation. In Proc. IPMI: International Conference on Information Processing and Medical Imaging. LNCS 10265, pp 1-13. 2017. 

~~~~
@inproceedings{dalca2017population,
  title={Population Based Image Imputation},
  author={Dalca, Adrian V and Bouman, Katherine L and Freeman, William T and Rost, Natalia S and Sabuncu, Mert R and Golland, Polina},
  booktitle={Information Processing in Medical Imaging},
  year={2017},
  pages={1--13},
  organization={Springer}
}
~~~~

or:  
A.V. Dalca, A. Bobu, N.S. Rost, P. Golland. Patch-Based Discrete Registration of Clinical Brain Images. In Proc. MICCAI-PATCHMI Patch-based Techniques in Medical Imaging, LNCS 9993, pp 60-67, 2016. 

~~~~
@inproceedings{dalca2016patch,
  title={Patch-Based Discrete Registration of Clinical Brain Images},
  author={Dalca, Adrian V and Bobu, Andreea and Rost, Natalia S and Golland, Polina},
  booktitle={International Workshop on Patch-based Techniques in Medical Imaging},
  pages={60--67},
  year={2016},
  organization={Springer}
}
~~~~
