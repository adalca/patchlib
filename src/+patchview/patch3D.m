function patch3D(patch, varargin)
% PATCH3D visualize a 3D patch
%   patch3D(patch) visualize a 3D patch, where patch is a 3D array.
%
%   patch3D(..., param, value) allows for specifications of the following param/value pairs:
%       viewParams: a 1x2 vector with [AZ, EL] parameters of view()
%       range: the range to display in relation to the patch. the default is {1:size(patch, 1), ...}
%           For example, if for a 5x5x3 patch, using a range of {1:5, 1:5, 3:5} would 
%
% requires PATCH_3Darray 
%   http://www.mathworks.com/matlabcentral/fileexchange/28497-plot-a-3d-array-using-patch/
%       content/PATCH_3Darray/PATCH_3Darray.m

    assert(exist('PATCH_3Darray', 'file') == 2, 'patchview.patch3D requires PATCH_3Darray()');
    inputs = parseInputs(patch, varargin{:});

    % plot
    PATCH_3Darray(patch, inputs.range{:}, inputs.cmap, 'col');

    % set up plot.
    axisLim = 0.5 + [zeros(1, 3); size(patch)];
    axisLim = axisLim(:)';
    axis(axisLim);
    view(inputs.viewParams);

end


function inputs = parseInputs(patch, varargin)
    
    cmap = gray(256);
    cmap(1, :) = 1;
    
    p = inputParser();
    p.addParameter('viewParams', [45, 45], @(x) isnumeric(x) && numel(x) == 2); % [az, el] from view();
    p.addParameter('range', getNdRange(size(patch)), @iscell);
    p.addParameter('cmap', cmap, @isnumeric);
    p.parse(varargin{:});
    inputs = p.Results;
end
