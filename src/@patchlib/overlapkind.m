function overlap = overlapkind(str, patchSize)
% OVERLAPSTRING overlap amount from a pre-specified overlap type, or overlap type from amount
%   overlap = overlapstring(str, patchSize) overlap amount from a pre-specified overlap string str
%       given patchSize:
%       'sliding' refers to a sliding window, giving an overlap of patchSize - 1 
%       'discrete' refers to discrete patches, so the overlap is 0 
%       'mrf' assumes an overlap of floor((patchSize - 1)/2) (e.g. 2 on [5x5] patch)
%
%   kind = overlapstring(patchOverlap, patchSize) overlap kind from an overlap amount, using the
%       correpondances above. If the overlap amount doesn't fit one of the corresponding counts,
%       kind is 'unknown';
%
% See Also: patchcount, grid
%
% Contact: adalca@csail.mit.edu

    assert(patchlib.isvalidoverlap(str));

    if ischar(str)
        switch str
            case 'mrf'
                overlap = floor((patchSize - 1)/2);
            case 'sliding'
                overlap = patchSize - 1;
            case 'discrete'
                overlap = 0;
            otherwise
                error('Unknown overlap method: %s', str);
        end
    else
        if all(str == floor((patchSize - 1)/2))
            overlap = 'mrf';
        elseif all(str == (patchSize - 1))
            overlap = 'sliding';
        elseif all(str == 0)
            overlap = 'discrete';
        else
            overlap = 'unknown';
        end
    end
            
                
