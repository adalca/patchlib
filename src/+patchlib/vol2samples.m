function [patches, locsamples, volsamples] = vol2samples(nSamples, patchSize, varargin)
% VOL2SAMPLES sample patches uniformly from the given volume(s)
% 
% patches = vol2samples(nSamples, patchSize, vols) sample patches from the given volume (if vols is
% numeric) or volumes (then vols is a cell of numeric volumes). patches is [nSamples x
% prod(patchSize)]. nSamples is a scalar, indicating the total number of patches to be sampled, or a
% vector [nVols x 1] indicating exactly how many samples per volume.
%
% patches = vol2samples(nSamples, patchSize, vols1, vols2, ...) behaves like vol2samples(nSamples,
% patchSize, vols1), but also returns the patches from vols2 at the same sampling locations at where
% the original patches came from vols1. patches is then a cell, with patches{1} giving the patches
% from vols1, patches{2} giving the (same location) patches but from vols2, etc. Each volsX group
% should have the same number of volumes. Also, volsX{1} should have the same size as volsY{1}. This
% is useful if you want to sample a set of volumes, for example, but also want the respective
% samples if the volumes had some volumetric attribute (e.g. weights) associated with them.
%
% patches = vol2samples(nSamples, patchSize, mfstruct, volname) allows for specification of volumes
% via a matfile struct. volname is the volume name (string) to be read from the matfile. if mfstruct
% is just a matfile pointer, we assume a single volume will be used. if matfile is a cell of matfile
% pointers, then vol2samples will sample from each volume, being equivalent to the call
% vol2samples(nSamples, patchSize, vols) with vols being a cell. Using matfiles is useful in cases
% where having all volumes in memory is infeasible. vol2samples only one volume at a time. Again,
% nSamples is a scalar or a vector of size [nMatFiles x 1].
%
% patches = vol2samples(nSamples, patchSize, mfstruct, volname1, volname2, ...) is the matfile
% pointer equivalent of vol2samples(nSamples, patchSize, vols1, vols2, ...).
%
% patches = vol2samples(..., withReplacement) allows for the specification of a logical on whether
% or not to do the sampling with replacement. The default is false.
%
% [patches, locsamples, volsamples] = vol2samples(...) also returns the location and volume id of
% the samples.
%
% See Also: vol2lib
%   
% Contact: {adalca,klbouman}@csail.mit.edu

    % input checking
    [nSamples, volstruct, volnames, replace] = parseInputs(nSamples, patchSize, varargin{:});
    [volsamples, locidx, volSizes] = sample(nSamples, volstruct, volnames, patchSize, replace);
    effVolSizes = bsxfun(@minus, volSizes, patchSize + 1); % effective (samplable) size
    nSamplesVol = hist(volsamples, 1:size(volSizes, 1));
    
    % get patches from samples
    patches = repmat({nan(nSamples, prod(patchSize))}, [1, numel(volnames)]);
    locsamples = nan(size(volsamples, 1), size(volSizes, 2));
    
    for vi = find(nSamplesVol(:)' > 0)
        inds = find(volsamples == vi);
        
        % load volume. 
        % if volstruct is a matfile, this is when MATLAB loads the file for the first time
        vol = volstruct{vi}.(volnames{1});

        % get locations
        locsamples(inds, :) = ind2subvec(effVolSizes(vi, :), locidx(inds));
        
        % extract patches via library.
        patches{1}(inds, :) = patchlib.vol2lib(vol, patchSize, 'locations', locsamples(inds, :));
        
        for x = 2:numel(volnames)
            vol = volstruct{vi}.(volnames{x});
            patches{x}(inds, :) = patchlib.vol2lib(vol, patchSize, 'locations', locsamples(inds, :));
        end 
    end
    
    if numel(volnames) == 1
        patches = patches{1};
    end
end

function [nSamples, mfstruct, volnames, replace] = parseInputs(nSamples, patchSize, varargin)

    % check inputs
    narginchk(3, inf);
    assert(isnumeric(nSamples));
    assert(isnumeric(patchSize));

    replace = false;
    if islogical(varargin{end})
        replace = varargin{end};
        varargin = varargin(1:end-1);
    end
    
    % check whether third argument is matfile(s) or volume(s)
    arg3 = varargin{1};
    arg3 = ifelse(iscell(arg3), arg3{1}, arg3);
    
    if isnumeric(arg3) % numeric volumes passed in.
        
        % get the final volume size
        nVols = [1, numel(varargin)];
        if iscell(varargin{1}), nVols(1) = numel(varargin{1}); end
        
        mfstruct = cell(nVols(1), 1);
        volnames = cell(1, nVols(2));
        for j = 1:nVols(2)
            volsX = varargin{j};
            volsX = ifelse(iscell(volsX), volsX, {volsX});
            assert(numel(volsX) == nVols(1));
            volnames{j} = sprintf('vol%d', j);
            
            for i = 1:nVols(1)    
                mfstruct{i}.(volnames{j}) = volsX{i};
            end
        end
        
    else % matfile struct passed in
        assert(nargin > 3, 'matfile version needs volume names');
        msg = 'The third argument should be either a numeric or matfile, or cell of either.';
        msg = sprintf('%s\nInstead, a %s was passed in', msg, class(arg3));
        assert(isa(arg3, 'matlab.io.MatFile'), msg);
        mfstruct = ifelse(iscell(varargin{1}), varargin{1}, varargin(1));
        
        assert(iscellstr(varargin(2:end)), 'matfile volumes should be strings');
        volnames = varargin(2:end);
    end
end

function [volidx, locidx, volSizes] = sample(nSamples, mfstruct, volnames, patchSize, replace)

    % get the volume sizes
    if isstruct(mfstruct{1})
        volSizes = cellfunc(@(x) size(x.(volnames{1})), mfstruct);
    else % matfile
        volSizes = cellfunc(@(m) size(m, volnames{1}), mfstruct);
    end
    volSizes = cat(1, volSizes{:});

    % make nSamples a vector (get the number of samples in each volume)
    nVols = numel(mfstruct);
    if replace 
        if isscalar(nSamples) 
            % sampling patches with replacement, so can freely sample volumes with replacement without
            % regard to over-sampling, etc.        
            vSample = randsample(nVols, nSamples, replace); 
            nSamples = hist(vSample, 1:nVols);
        end
        
        assert(numel(nSamples) == numel(mfstruct))
        [volidx, locidx] = samplePatchesInVol(nSamples, volSizes, replace);
        
    % without replacement, need to worry about size of samples assigned to each volume. For
    % example, need to avoid wanting to sample more samples from volume 1 than are available.
    else
        if isscalar(nSamples)
            effVolSizes = bsxfun(@minus, volSizes, patchSize + 1); % effective (samplable) size
            totSizes = prod(effVolSizes, 2);
            assert(nSamples <= sum(totSizes)); % make sure we're not asking for too many samples.
            
            % method to avoid making a huge vector: sample assuming you have an exploded vector, and
            % then loop though the possible volumes.
            idx = randsample(sum(totSizes), nSamples);
            
            ctotSizes = [0, cumsum(totSizes(:)')];
            ci = 0;
            for i = 1:numel(mfstruct)
                f = find(idx >= (ctotSizes(i) + 1) & idx <= ctotSizes(i+1));
                locidx((ci + 1):(ci + numel(f))) = idx(f) - ctotSizes(i);
                volidx((ci + 1):(ci + numel(f))) = i;
                ci = ci + numel(f);
            end
            assert(ci == nSamples);
            volidx = volidx(:);
            locidx = locidx(:);
            
        else
            assert(numel(nSamples) == numel(mfstruct));
            [volidx, locidx] = samplePatchesInVol(nSamples, volSizes, replace);
        end
    end
end

function [volidx, locidx] = samplePatchesInVol(nSamples, volSizes, replace)
    volidx = zeros(nSamples, 1);
    locidx = zeros(nSamples, 1);

    assert(numel(nSamples) == numel(mfstruct));
    ci = 1;
    for i = 1:numel(nSamples)
        locidx((ci + 1):(ci + nSamples(i))) = randsample(nSamples(i), prod(volSizes(i, :)), replace);
        volidx((ci + 1):(ci + nSamples(i))) = i;
        ci = ci + nSamples(i);
    end
    assert(ci == sum(nSamples));
end
