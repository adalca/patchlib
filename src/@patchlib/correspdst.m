function dst = correspdst(pstr1, pstr2, ~, ~, dvFact)

    if nargin == 4
        dvFact = 100;
    end

    % assumes patches is Nx2 where the second is [x, y]
    dst = pdist2(pstr1.disp ./ dvFact, pstr2.disp ./dvFact);
    dst = min(dst, 1);
    
%     error('this might be wrong. need to subtract patchOverlap from patches2?');
end