function isv = isvalidoverlap(overlap)
    
    isv = isnumeric(overlap) || ismember(overlap, {'sliding', 'half', 'discrete'});
