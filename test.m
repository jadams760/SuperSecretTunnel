addpath(genpath('/mpeg/'));
addpath(genpath('/TEMP/'));
imagesDir = dir('High5_PNG/*.png');
files = cell(1,length(imagesDir));
doubleFiles = cell(1,length(imagesDir));
iFrames = cell(1,length(imagesDir));
pFrames = cell(1,length(imagesDir));
bFrames = cell(1,length(imagesDir));
outFrames = cell(1,length(imagesDir));

for i = 1:4:length(imagesDir)
    files{i} = imresize(rgb2gray(imread(strcat('High5_PNG/',imagesDir(i).name))),[256 384]);
    %files{i} = double(imresize(rgb2gray(imread(strcat('High5_PNG/',imagesDir(i).name))),[256 384]));
    iFrames{i} = double(files{i});
    if i > 2
        bFrames{i-1} = double(files{i-1});
    end
    bFrames{i+1} = double(files{i+1});
    if i < length(imagesDir) - 4
        pFrames{i+2} = double(files{i+2});
    end
    %doubleFiles{i} = double(files{i});

end


encoded_I = cell(1,length(imagesDir));
[code dict dim] = JPEG1(iFrames{1});  



