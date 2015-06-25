function sub = corresp2sub(varargin) 
% goes from reference indexes to subscripts into those references.
%
% options:
%   sub = corresp2sub(refsizes, pIdx) % defaults rIdx = 1 and refgrididx = 1:prod(refsize)
%   sub = corresp2sub(refsizes, pIdx, rIdx) % defaults refgrididx = 1:prod(refsize)
%   sub = corresp2sub(refsizes, pIdx, rIdx, refgrididx)

    narginchk(2, 4); % inputs should be between 1 and 4 as seen in comments above


    % get the reference sizes, pIdx, rIdx, refgrididx
    refsize = varargin{1};
    if ~iscell(refsize), refsize = {refsize}; end
    pIdx = varargin{2};
    rIdx = ifelse(nargin < 3, 'ones(size(pIdx))', 'varargin{3}', true);
    assert(numel(refsize) >= max(rIdx(:)), 'not enough reference sizes have been passed');
    refgrididx = ifelse(nargin < 4, 'cellfunc(@(x) 1:prod(x), refsize)', 'varargin{4}', true);
    if ~iscell(refgrididx), refgrididx = {refgrididx}; end

    % prepare the correspondances (initiate with zeros)
    sub = repmat({zeros(size(pIdx))}, [1, numel(refsize{1})]);

    % go through each reference, and compute the subscripts for the
    % indexes used from that reference.
    for i = 1:numel(refsize)
        rMap = rIdx == i;
        gMap = refgrididx{i};
        rCorresp = cell(1, numel(refsize{i}));
        [rCorresp{:}] = ind2sub(refsize{i}, gMap(pIdx(rMap)));

        for d = 1:numel(refsize{1})
            sub{d}(rMap) = rCorresp{d};
        end
    end
end