function out = motion_vectors_decode(code,dict)

    dsig = huffmandeco(code,dict);

    out = reshape(dsig,2,[]);