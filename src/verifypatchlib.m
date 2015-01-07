warning off backtrace

% get current path;
datapath = fileparts(mfilename('fullpath'));

% get patchlib path
datapath = fileparts(datapath);

% add patchlib paths
addpath(genpath(datapath));

% verify
assert(sys.isfile('example_patchmrf.m'), 'example path not added');
assert(sys.isfile('UGM_Infer_LBP'), ...
    'Could not find UGM. Please download at %s, run UGM''s mexAll, and add to matlab path.', ...
    'http://www.cs.ubc.ca/~schmidtm/Software/UGM.html');
disp('patchmrf verification complete');
