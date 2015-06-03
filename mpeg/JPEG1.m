function [code dict dim] = JPEG1 (image)

dim = size(image) ;
fid = fopen('Qtable2.txt','r');
%array is quantization matrix
array = fscanf(fid,'%e',[8,inf]);

JQ = forwardDCT(image,array);

JQ_vect = reshape(JQ,1,[]);

uniq_JQ = unique(JQ_vect);
% Value - # occurrences
p = histc(JQ_vect,uniq_JQ) / prod(dim);

[dict,avglen] = huffmandict(uniq_JQ,p); % Create dictionary.
actualsig = JQ_vect; % Create data using p.
code = huffmanenco(actualsig,dict); % Encode the data.