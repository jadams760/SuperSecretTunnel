function out = inverse_JPEG(code,dict)

dsig = huffmandeco(code,dict);

JQ = reshape(dsig,256,[]);

fid = fopen('Qtable2.txt','r');

array = fscanf(fid,'%e',[8,inf]);

inverseD = inverseDCT(JQ,array);

out = inverseD;
