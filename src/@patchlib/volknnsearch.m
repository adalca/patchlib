function [patches, pDst, pIdx, pRefIdxs, srcgridsize] = volknnsearch(src, refs, patchSize, varargin)
% VOLKNNSEARCH k-NN search of patches in source given a set of reference volumes
%     patches = volknnsearch(src, refs, patchSize) k-NN search of patches in source volume src given
%     a set of reference volumes refs. refs can be a volume or a cell of volumes, of the same
%     dimentionality as src. patchSize is the size of the patches. patches is a [M x V x K] array,
%     with M being the number of patches, V the number of voxels in a patch, and K from kNN.
% 
%     patches = volknnsearch(src, refs, patchSize, patchOverlap) allows the specification of a
%     patchOverlap amount or kind for src. See patchlib.overlapkind for more information. Default is
%     the default used in patchlib.vol2lib.
% 
%     patches = volknnsearch(src, refs, patchSize, srcPatchOverlap, refsPatchOverlap) allows the
%     specification of a patchOverlap amount or kind for refs as well.
% 
%     patches = volknnsearch(..., Param, Value) allows for parameter/value pairs that are passed
%     down to knnsearch(...).
% 
%     [patches, pDst, pIdx, pRefIdx, srcgridsize] = volknnsearch(...) also returns  the patch
%     indexes (M x K) into the reference libraries, pRefIdxs (M x 1) indexing the libraries for
%     every patch, and pDst giving the distance of every patch resulting from knnsearch().
%     srcgridsize is the source grid size.
%
% Contact: adalca@csail.mit.edu

    % inputs
    narginchk(3, inf);
    [refs, srcoverlap, refoverlap, knnvarargin] = parseinputs(refs, varargin{:});
    
    % source library
    [srclib, ~, ~, srcgridsize] = patchlib.vol2lib(src, patchSize, srcoverlap{:});
    
    % build the libraries
    [refslibCell, ~, ~, ~, refsidxCell] = patchlib.vol2lib(refs, patchSize, refoverlap{:});
    
    % compute one ref library, and associated indexes
    refslib = cell2mat(refslibCell);
    refsidx = cell2mat(refsidxCell);
    
    % do knn
    [pIdx, pDst] = knnsearch(refslib, srclib, knnvarargin{:});
    pRefIdxs = refsidx(pIdx);
    
    % return patches
    patches = patchlib.lib2patches({refslib}, pIdx, pRefIdxs, patchSize);

end


function [refs, srcoverlap, refoverlap, varargin] = parseinputs(refs, varargin)
% getPatchFunction (2dLocation_in_src, ref), 
% method for extracting the actual stuff - this can probably be put with getPatchFunction. 
% pre-sel voxels?
% Other stuff for knnsearch
    
    if ~iscell(refs)
        refs = {refs};
    end

    srcoverlap = {};
    if numel(varargin) > 1 && patchlib.isvalidoverlap(varargin{1})
        srcoverlap = varargin(1);
        varargin = varargin(2:end);
    end
    
    refoverlap = {};
    if numel(varargin) > 1 && patchlib.isvalidoverlap(varargin{1})
        refoverlap = varargin(1);
        varargin = varargin(2:end);
    end
end
