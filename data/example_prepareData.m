function varargout = example_prepareData(type, noisestd, varargin)
    
    datapath = fileparts(mfilename('fullpath'));
    
    switch type
        case 'boston-pano-sunset'
            
            im1 = im2double(imread(fullfile(datapath, 'boston-pano-sunset-crop1.jpg')));
            im2 = im2double(imread(fullfile(datapath, 'boston-pano-sunset-crop2.jpg')));
            
            % desired
            varargout{1} = im1;
            
            % src/target
            varargout{2} = within([0, 1], normrnd(im1, noisestd));
            
            % reference
            varargout{3} = im2;
            
        case 'pepper'
            % load image. We'll crop around a small pepper.
            imd = im2double(imread('peppers.png'));
            im = imresize(imd(220:320, 100:200, :), [25, 25]);
            
            
            % simulate a noisy image
            noisyim = normrnd(im, noisestd);
            noisyim = within([0, 1], noisyim);
            im = within([0, 1], im);
            
            varargout{1} = im;
            varargout{2} = noisyim;
            
        otherwise
            error('Unknown data example type');
    end
    
    disp('Data loaded');
end
            
