function [code,dict] = motion_vectors_encode(motionVector)
    dim = size(motionVector)
    JQ_vect = reshape(motionVector,1,[]);

    uniq_JQ = unique(JQ_vect);
    % Value - # occurrences
    p = histc(JQ_vect,uniq_JQ) / prod(dim);

    [dict,avglen] = huffmandict(uniq_JQ,p); % Create dictionary.
    actualsig = JQ_vect; % Create data using p.
    code = huffmanenco(actualsig,dict); % Encode the data.