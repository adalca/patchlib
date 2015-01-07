function patchSize = guessPatchSize(n, dim)
% GUESSPATCHSIZE attempt to guess the size of a patch
%   patchSize = guessPatchSize(n) attempt to guess the size of a patch with n pixels based on the
%       factorization of n and common expected patches
%
%   patchSize = guessPatchSize(n, dim) allows the specification of the number of dimensions of a
%       patch.
%
% Examples:
%     patchlib.guessPatchSize(25)
%     ans =
%          5     5
%     patchlib.guessPatchSize(30)
%     ans =
%          2     3     5
%     patchlib.guessPatchSize(30, 2)
%     ans =
%          6     5
%
% Contact: adalca@csail.mit.edu

    % factor the number of pixels
    facts = factor(n);
    
    % go through the possible number of factors
    switch numel(facts)
        
        case 2
            % needs to be 2D
            if nargin == 2
                assert(dim == 2, 'only two factors found. Patch Size estimation failes');
            end
            
            patchSize = facts;
            
        case 3
            if nargin == 1
                dim = 3;
            end
            
            if dim == 3
                patchSize = facts;
            else
                patchSize = [facts(1) * facts(2), facts(3)];
            end
            
        case 4
            if nargin == 1
                dim = 2;
            end
            
            if dim == 2
                patchSize = [facts(1) * facts(2), prod(facts(3:end))];
            elseif dim == 3
                patchSize = [facts(1) * facts(2), facts(3), facts(4)];
            else
                assert(dim == 4);
                patchSize = facts;
            end
        otherwise
            error('Cannot detect patch Size');
    end
    
    if nargin == 2
        assert(length(patchSize) == dim);
    end
end
                