patchlib
========

A library for working with N-D patches, also including several 2D and 3D examples to illustrate the library applicability.

- See [`functions`](src/functions.md) for a (non-exhaustive) list of functions.
- See [`examples`](examples/examples.md) for a list of examples to get you started.
- See [papers](#papers) section below for a list of academic papers in which we used this library


Installation
-------

#### Set up code
Do a git pull or download patchlib as a zip. Unzip the files, and add the folder to your MATLAB path:  
`>> addpath(genpath('PATH_TO_PATCHLIB'));`

Then run setup script:  
`>> verifypatchlib.m;`

#### Dependencies
Add each of the following toolboxes to your MATLAB path:

The following toolbox is required by all of the code:
- [matlib](https://github.com/adalca/matlib)

The MRF-related methods (e.g. for spatial regularization):
- [UGM library by Mark Schmidt](http://www.cs.ubc.ca/~schmidtm/Software/UGM.html)


Papers
--------
If you find this library useful, please cite one of the following papers for which the library was initially built ([download bib](citations.bib)):  

- **Medical Image Imputation from Image Collections**  
[A.V. Dalca](http://adalca.mit.edu), [K.L. Bouman](https://people.csail.mit.edu/klbouman/), [W.T. Freeman](https://billf.mit.edu/), [M.R. Sabuncu](http://sabuncu.engineering.cornell.edu/), [N.S. Rost](https://www.massgeneral.org/doctors/doctor.aspx?id=17477), [P. Golland](https://people.csail.mit.edu/polina/)  
IEEE TMI: Transactions on Medical Imaging 38.2 (2019): 504-514. eprint [arXiv:1808.05732](https://arxiv.org/abs/1808.05732)  

- **Population Based Image Imputation**  
[A.V. Dalca](http://adalca.mit.edu), [K.L. Bouman](https://people.csail.mit.edu/klbouman/), [W.T. Freeman](https://billf.mit.edu/), [M.R. Sabuncu](http://sabuncu.engineering.cornell.edu/), [N.S. Rost](https://www.massgeneral.org/doctors/doctor.aspx?id=17477), [P. Golland](https://people.csail.mit.edu/polina/)  
In Proc. IPMI: International Conference on Information Processing and Medical Imaging. LNCS 10265, pp 1-13. 2017. 

- **Patch-Based Discrete Registration of Clinical Brain Images**  
[A.V. Dalca](http://adalca.mit.edu), [A. Bobu](https://people.eecs.berkeley.edu/~abobu/), [N.S. Rost](https://www.massgeneral.org/doctors/doctor.aspx?id=17477), [P. Golland](https://people.csail.mit.edu/polina/)  
In Proc. MICCAI-PATCHMI Patch-based Techniques in Medical Imaging, LNCS 9993, pp 60-67, 2016. 

Contributors
------------
Adrian Dalca ([web](http://adalca.mit.edu) | [email](mailto:adalca@mit.edu))  
Katie Bouman ([web](http://people.csail.mit.edu/klbouman) | [email](mailto:klbouman@csail.mit.edu))

**Contact** Please let us know of any questions/suggestions by opening an [issue](https://github.com/adalca/patchlib/issues) or emailing us at {adalca,klbouman}@csail.mit.edu
