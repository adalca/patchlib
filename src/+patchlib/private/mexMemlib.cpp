/*===========================================================================*
* memlib.c
* Compute library in memory
*
* patchlib
* Contact: adalca@mit.edu
*===========================================================================*/

#include <mex.h>
#include "matrix.h"

/**
* Compute library in memory
*/
mxArray* vol2memlib(const mxArray* inVol, const mxArray* inInitsub, const mxArray* inShift) {
    
    int i, j, d; // counters
    int idx, multdims;
    
    // get useful factors and pointers
    const double* vol = mxGetPr(inVol);
    const mwSize* cropVolSize = mxGetDimensions(inVol);
    const double* shift = mxGetPr(inShift);
    size_t M = mxGetM(inShift);
    size_t nPatches = mxGetNumberOfElements(mxGetCell(inInitsub, 0));

    // get dimensions
    const size_t nDims = mxGetN(inInitsub);
    mxAssert(nDims == mxGetNumberOfDimensions(inVol), "Number of dimensions does not match");
    
    // load initsub
    double** initsub = (double**) mxMalloc(nDims * sizeof(double*));
    for (d = 0; d < nDims; d++) {
        initsub[d] = mxGetPr(mxGetCell(inInitsub, d));
    }
    
    //  prepare indices and output library
    double* offset, patch;
    mxArray* res = mxCreateDoubleMatrix((int) nPatches, (int) M, mxREAL);
    double* lib = mxGetPr(res);

    // build library
    for (i = 0; i < nPatches; i++) { // for each patch
        for (j = 0; j < M; j++) { // for each shift
            
            // get the shit pointer
            offset = (double*) shift + j;
            
            // sub2ind, basically. use -1 because of matlab 1 indexing
            // inspired by sub2ind_mex by Christopher Harris
            idx = (long) (initsub[0][i]-1 + offset[0]-1); // initial index for dimention 0
            multdims = 1;
            for (d = 1; d < nDims; d++) {
                multdims *= (double) cropVolSize[d - 1];
                idx += (long) (initsub[d][i]-1 + (*(offset+d*M))-1) * multdims;
            }
            
            // assign to library
            lib[i + j * nPatches] = *(vol + idx);
        }
    }
    
    return res;
}

/**
* Entry point.
*/
void mexFunction(int nlhs, mxArray* plhs[], int nrhs, const mxArray* prhs[]) {
	
    /* todo - checking */
	plhs[0] = vol2memlib(prhs[0], prhs[1], prhs[2]); 
}

