addpath(genpath('mpeg/'));
addpath(genpath('TEMP/'));
addpath(genpath('Actual JPEG/'));
imagesDir = dir('High5_PNG/*.png');
addpath(genpath('High5_PNG/'));
files = cell(1,length(imagesDir));

iFrames = cell(1,length(imagesDir));
pFrames = cell(1,length(imagesDir));
bFrames = cell(1,length(imagesDir));
outFrames = cell(1,length(imagesDir));

N_macro = 8;
p = 16;

for i = 1:length(imagesDir)
    files{i} = double(imresize(rgb2gray(imread(strcat('High5_PNG/',imagesDir(i).name))),[256 384]));

end

for i = 1:4:length(imagesDir)
    iFrames{i} = files{i}
    if i > 2
        bFrames{i-1} = files{i-1};
    end
    
    
    if i == length(imagesDir) - 1
        iFrames{i+1} = files{i+1};
    else
        bFrames{i+1} = files{i+1};
    end
    
    if i < length(imagesDir) - 4
        pFrames{i+2} = files{i+2};
    end
    
end

encodedI = cell(1,length(imagesDir))
encodedP = cell(1,length(imagesDir))
encodedB = cell(1,length(imagesDir))

for i = 1:length(imagesDir)
    if ~isempty(iFrames{i})
        [tmpcode tmpdict tmplen] = JPEG1(iFrames{i})
        encodedI{i} = inverse_JPEG(tmpcode,tmpdict)
    end
end

for i = 3 : 4 : length(imagesDir)
    
    motionVect = motionEstES(iFrames{i-2}, pFrames{i}, N_macro, p) ; % Motion Vectors
    P_comp_temporary = motionComp(iFrames{i-2}, motionVect, N_macro);

    P_Error = pFrames{i} - P_comp_temporary ; % Residual 
    [encoded_error_P_code, error_dict, error_len] = JPEG1(P_Error); % Encoded residual bitstream
    [encoded_motion_vectors_P_code, vec_dict] = motion_vectors_encode(motionVect); % Encoded motion vector 
    
    error_dec = inverse_JPEG(encoded_error_P_code, error_dict);
    vec_dec = motion_vectors_decode(encoded_motion_vectors_P_code, vec_dict);
    
    
    encodedP{i} = motionComp(encodedI{i-2}, vec_dec, N_macro) + error_dec; % Decoded P frame
    
end


for i = 2:2:length(imagesDir) - 1
    if mod(idivide(uint8(i),2),2) == 0 
        motionVectI = motionEstES(iFrames{i+1}, bFrames{i}, N_macro, p) ; % Motion Vectors Forward Flow
        motionVectP = motionEstES(pFrames{i-1}, bFrames{i}, N_macro, p) ; % Motion Vectors Backward Flow

        B_comp_I = motionComp(iFrames{i+1}, motionVectI, N_macro);
        B_comp_P = motionComp(pFrames{i-1}, motionVectP, N_macro);

        B_Recons = (B_comp_I + B_comp_P) / 2;

        B_Error = bFrames{i} - B_Recons ; % Residual

        [encoded_error_B_code, error_dict, error_len] = JPEG1(B_Error); % Encoded residual bitstream
        [encoded_motion_vectors_B_I_code, vec_BI_dict] = motion_vectors_encode(motionVectI); % Encoded motion vector 
        [encoded_motion_vectors_B_P_code, vec_BP_dict] = motion_vectors_encode(motionVectP); % Encoded motion vector 
        
        error_dec = inverse_JPEG(encoded_error_B_code, error_dict);
        vec_dec_BI = motion_vectors_decode(encoded_motion_vectors_B_I_code, vec_BI_dict);
        vec_dec_BP = motion_vectors_decode(encoded_motion_vectors_B_P_code, vec_BP_dict);
        
        temp1 = motionComp(encodedI{i+1}, vec_dec_BI, N_macro);
        temp2 = motionComp(encodedP{i-1}, vec_dec_BP, N_macro);
        encodedB{i} = error_dec + (temp1+temp2)/2;
        
    else
        motionVectI = motionEstES(iFrames{i-1}, bFrames{i}, N_macro, p) ; % Motion Vectors Forward Flow
        motionVectP = motionEstES(pFrames{i+1}, bFrames{i}, N_macro, p) ; % Motion Vectors Backward Flow

        B_comp_I = motionComp(iFrames{i-1}, motionVectI, N_macro);
        B_comp_P = motionComp(pFrames{i+1}, motionVectP, N_macro);

        B_Recons = (B_comp_I + B_comp_P) / 2;

        B_Error = bFrames{i} - B_Recons ; % Residual

        [encoded_error_B_code, error_dict, error_len] = JPEG1(B_Error); % Encoded residual bitstream
        [encoded_motion_vectors_B_I_code, vec_BI_dict] = motion_vectors_encode(motionVectI); % Encoded motion vector 
        [encoded_motion_vectors_B_P_code, vec_BP_dict] = motion_vectors_encode(motionVectP); % Encoded motion vector 
        
        error_dec = inverse_JPEG(encoded_error_B_code, error_dict);
        vec_dec_BI = motion_vectors_decode(encoded_motion_vectors_B_I_code, vec_BI_dict);
        vec_dec_BP = motion_vectors_decode(encoded_motion_vectors_B_P_code, vec_BP_dict);
        
        temp1 = motionComp(encodedI{i-1}, vec_dec_BI, N_macro);
        temp2 = motionComp(encodedP{i+1}, vec_dec_BP, N_macro);
        encodedB{i} = error_dec + (temp1+temp2)/2;
    end
end

for i = 1:length(imagesDir)
    if ~isempty(encodedI{i})
        outFrames{i} = uint8(encodedI{i});
        
    elseif ~isempty(encodedP{i})
        outFrames{i} = uint8(encodedP{i});
    
    else ~isempty(encodedB{i})
        outFrames{i} = uint8(encodedB{i});
    end
end

t = readtable('caption.csv');
numCaptions = size(t,1);

color = [0 0 0];
location = [40 220];
stop = t{3,{'StartFrame'}} + t{3,{'Duration'}};
for i = 1 : numCaptions
    caption = t{i,{'Text'}};
    text = vision.TextInserter(char(caption));
    text.Color = color;
    text.FontSize = 18;
    text.Location = location;
    
    for j = t{i,{'StartFrame'}} : t{i,{'StartFrame'}} + t{i,{'Duration'}}
        outFrames{j} = step(text, outFrames{j});
    end
end

mkdir('out');
addpath(genpath('out'));
outVideo = VideoWriter(fullfile('out','out.avi'));
outVideo.FrameRate = 10;
open(outVideo);

for i = 1:30
    imwrite(outFrames{i},strcat('out/out',i,'.png'));
    writeVideo(outVideo,imread(strcat('out/out',i,'.png')));
end

close(outVideo);
