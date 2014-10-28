function examples_drawRow(nRows, rowid, ims, titles)
% nRows - number of subplot rows
% rowid - the current row being plotted
% ims - a cell of the images to plot
% titles - a cell of the titles to show 

    nCols = numel(ims);

    for i = 1:nCols
        subplot(nRows, nCols, nCols*(rowid-1) + i);
        imshow(ims{i}, 'InitialMagnification', 'fit'); 
        title(titles{i});
    end
    drawnow();
    