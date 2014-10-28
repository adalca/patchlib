function mrfComparePatches(mode, patchSizes, libraries, varargin)
% patchSizes and libraries are arrays
%
% egs: 
%   ps = {params.run.patchSize, params.mrf.hrPatchSize};
%   libs = {reference.lrLibrary, reference.hrLibrary};
%   mrfComparePatches('rand-mid', ps, libs, 5);
%   mrfComparePatches('rand-ds', ps, libs, ps{1}, 5);
    
    narginchk(3, inf);
    nElems = numel(patchSizes);
    assert(nElems == numel(libraries));
    assert(nElems > 0);

    liblen = size(libraries{1}, 1);

    switch mode
        % random index, middle slice
        case 'rand-mid'
            % if varargin is 1, it should be the number of patches to look at
            % get random indexes
            [idx, nIdx] = getIdx(1, liblen, varargin{:});
    
            figure();
            for i = 1:nIdx
                for e = 1:nElems
                    assert(all(isodd(patchSizes{e})))
                    im = lib2imSelect(libraries{e}, idx(i), patchSizes{e});

                    % show
                    subplot(nIdx, nElems, nElems * (i-1) + e);
                    imagesc(im, [0, 1]); colormap gray;
                end
            end

        % random index, downsample all patches to a specific patch size
        case 'rand-ds'
            % varargin{1} should be dstPatchSize to which all patches will be resized
            assert(numel(varargin) >= 1, 'We require at least the dst patchSize')
            dstPatchSize = varargin{1};
            mid = (dstPatchSize + 1)/2;

            % if varargin is 2, it should be the number of patches to look at
            % get random indexes
            [idx, nIdx] = getIdx(2, liblen, varargin{:});

            figure();
            for i = 1:nIdx
                for e = 1:nElems
                    assert(all(isodd(patchSizes{e})))
                    im = lib2imSelect(libraries{e}, idx(i), patchSizes{e}, 1:dstPatchSize(3));
                    im = volresize(im, dstPatchSize);
                    im = im(:, :, mid(3));

                    % show
                    subplot(nIdx, nElems, nElems * (i-1) + e);
                    imagesc(im, [0, 1]); colormap gray;
                end
            end

        otherwise
            error('unfinished');
            
    end
end

function [idx, nIdx] = getIdx(argIdx, liblen, varargin)
% argIdx - the index in varargin that we expect the nIdx to be.

    if numel(varargin) == argIdx
        nIdx = 1;
    else
        nIdx = varargin{argIdx};
    end
    idx = randi([1, liblen], nIdx, 1);
end

function im = lib2imSelect(lib, idx, patchSize, slicesIdx)
    if nargin == 3
        slicesIdx = (patchSize+1)/2;
        slicesIdx = slicesIdx(3);
    end

    im = lib(idx, :);
    im = reshape(im, patchSize);

    im = im(:,:,slicesIdx);

end
