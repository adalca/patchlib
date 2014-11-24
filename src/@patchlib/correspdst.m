function dst = correspdst(pstr1, pstr2, ~, ~, dvFact, usemex)

    if nargin <= 4 || isempty(dvFact)
        dvFact = 100;
    end
    
    if nargin <= 5
        usemex = false;
    end
    
    
    X = pstr1.disp ./ dvFact;
    Y = pstr2.disp ./ dvFact;
    
    % assumes patches is Nx2 where the second is [x, y]
    % Note: sinec we call pdist2 many times with relatively few samples, this takes extra time since
    % pdist2 does quite a bit of argument checking before calling pdist2mex. pdist2mex is a built-in
    % private function in the statistics toolbox. To make this part much faster than pdist2(),
    % copy the pdist2mex file somewhere on your path. Note, however, that having an if statement
    % that checks for (exist('pdist2mex', 'file') == 3) would be very costly, since that's a file
    % system check at every call. 
    if usemex
        dst = pdist2mex(X',Y','euc',[],[],[]);
    else
        dst = pdist2(pstr1.disp ./ dvFact, pstr2.disp ./dvFact);
    end
    
    dst = min(dst, 1);
    
%     error('this might be wrong. need to subtract patchOverlap from patches2?');
end