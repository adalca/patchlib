function h = figure()
    ret = ifelse(exist('figuresc', 'file') == 2, @figuresc, @figure); 
    h = ret();
