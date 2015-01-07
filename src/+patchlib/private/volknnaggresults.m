function [pDst, pIdx, rIdx, srcgridsize, refgridsize] = volknnaggresults(vin, inputs)
% private function for volknnsearch.

    [~, pDstm, pIdxm, rIdxm, srcgridsize, refgridsize] = deal(cell(numel(vin), 1));
    for i = 1:numel(vin)
        [~, pDstm{i}, pIdxm{i}, rIdxm{i}, srcgridsize{i}, refgridsize{i}] = vin{i}{:};
    end

    K = size(pDstm{1}, 2);
    nRefs = numel(vin);
    switch inputs.separateProcAgg

        % aggregate results based on distances
        case 'agg'

            % join structures
            pDstm = cat(2, pDstm{:});
            pIdxm = cat(2, pIdxm{:});
            rIdxm = cellfunc(@(x, y) (x * y), rIdxm, num2cell(1:nRefs)');
            rIdxm = cat(2, rIdxm{:});

            % sort results
            [~, si] = sort(pDstm, 2, 'ascend');

            % combine the top results
            nElems = size(pIdxm, 1);
            pIdx = zeros(nElems, K);
            rIdx = zeros(nElems, K);
            pDst = zeros(nElems, K);
            
            for i = 1:size(pDstm, 1)
                pDst(i, :) = pDstm(i, si(i, 1:K));
                pIdx(i, :) = pIdxm(i, si(i, 1:K));
                rIdx(i, :) = rIdxm(i, si(i, 1:K));
            end

        % just return separate results
        case 'sep'
            for i = 1:nRefs
                pDst = pDstm;
                pIdx = pIdxm;
                rIdx = rIdxm;
            end

        otherwise
            error('unknown method')
    end
    
    srcgridsize = srcgridsize{1};
end
