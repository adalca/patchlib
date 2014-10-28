function library = mrfVolStruct2lib(volStruct, patchSize, varargin)
% similar to mrfVol2lib, but takes in a volStruct instead of a volume
% Returns horizontally concatenanted features.
%
% See Also mrfVol2lib
    
    % compute cell of feature-volumes
    vols = volStruct2featVols(volStruct);
    
    % compute libraries on mrf grid
    libraries = mrfVols2libs(vols, patchSize, varargin{:});
    
    % add horizontally
    library = cell2mat(libraries(:)'); 
end