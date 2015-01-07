function varargout = volStruct2lib(volStruct, patchSize, varargin)
% similar to vol2lib, but takes in a volStruct, not volume. 
%
% See Also: vol2lib
%
% Contact: {adalca,klbouman}@csail.mit.edu

    % some input checks
    narginchk(2, 3);
   
    % compute cell of feature-volumes
    vols = volStruct2featVols(volStruct);
    if numel(vols) == 1
        vols = vols{1};
    end
    
    % compute libraries
    [libraries, idx] = patchlib.vol2lib(vols, patchSize, varargin{:});
    
    % add horizontally
    varargout{1} = libraries;
    
    if nargout == 2
        % should actually be consistent!
        varargout{2} = idx;
    end 
end
