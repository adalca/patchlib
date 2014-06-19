function layers2D(layers, mode, varargin)
% VIEWLAYERS2D view layers (as returned by patchlib.stackPatches)
%   viewLayers2D(layers) see layers in separate subplots.
%
%   viewLayers2D(layers, 'discrete') see each layer in a separate subplot (default)
%
%   viewLayers2D(layers, 'discrete', patchSize) see each layer in a separate subplot, and plot
%       gridlines for patches
%
%   viewLayers2D(layers, 'stack') see a 3-D axis with the layers on top of each other.
%
%   viewLayers2D(layers, 'stack', alpha) same as stack, but each layer is only shown with
%       transparency amount given by alpha. This leads to a cute demo - setting the alpha to
%       1/nLayers will make each layer fairly transparent. However, if you spin the axis
%       interactively to look at the layers head-on, the 'average image' accross all layers will be
%       seen :)
%       
% Contact: adalca@csail.mit.edu

    assert(ndims(layers) == 3, ...
        'Layers needs to have [nLayers x height x width] format, i.e. 2D layers with K = 1');
    
    if nargin == 1
        mode = 'discrete';
    end
    
    switch mode
        case 'discrete'
            
            nLayers = size(layers, 1);
            volSize = [size(layers, 2), size(layers, 3)];
            
            % display the layers using the first NN
            v = reshape(layers, [nLayers, prod(volSize)]);
            [~, nElems] = patchview.patches2D(v, volSize, [], 'subplot');
            
            % add grids to all the plots
            if numel(varargin) > 0
                patchSize = varargin{1};
                sub = ind2subvec(patchSize, (1:prod(patchSize))');
                for i = 1:size(layers, 1)
                    subplot(nElems, nElems, i); hold on;
                    xRange = (sub(i, 2):patchSize(2):volSize(2)+1) - 0.5;
                    yRange = (sub(i, 1):patchSize(1):volSize(1)+1) - 0.5;
                    drawgrid(xRange, yRange, 'r');
                end
            end
            
        case 'stack'
            alph = 1;
            if numel(varargin) > 0
                alph = varargin{1};
            end
            if numel(varargin) < 2
                patchview.figure(); 
            end
                
            
            % display the 25 layers using the first NN
            hold on;
            for i = 1:size(layers, 1)
                hi = imageIn3D(squeeze(layers(i, :, :)), i);
                alpha(hi, alph);
                colormap gray;
            end
            view(30,30);
            title('Stack of patch layers as given by stackPatches')
            
        otherwise
            error('Unknown view mode.');
    
    end
end
