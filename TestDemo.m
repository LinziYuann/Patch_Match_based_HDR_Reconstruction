%% BatchTestDemo
clc, clear, close all;

%% change directory
prev_dir = pwd; file_dir = fileparts(mfilename('fullpath')); cd(file_dir);
addpath(genpath(pwd));

%% read source image sequence
DataPath = '.\data\';
AlignSavePath = '.\alignSave\';
makeDir(AlignSavePath);

SceneFolderStruct = dir(DataPath);
SceneCell = {SceneFolderStruct(3:end).name}; % 2 unexist file name
flag = 0;
refID = 2;
%% for each Scene
for n = 1:size(SceneCell,2)  %train 9
    Scene = SceneCell{n};
    baseline = load(fullfile(DataPath, Scene, 'dmin.txt'));
    makeDir(fullfile(AlignSavePath, Scene));
    fprintf('====== Scene%d: %s ======\n',n, Scene);

    tic
    expo = loadExpoExp(fullfile(DataPath, Scene), flag);
    [imgSeqColor,imgRefLdr,N] = loadImg(fullfile(DataPath, Scene), refID); %
    [fI, Ann,countMap,diffy] = DirectMerge(imgSeqColor, baseline,'wSize',7,'stepSize',1);
    toc
    %% write image
    imwrite(fI(:,:,:,1).^(1/2.2), fullfile(AlignSavePath, Scene, 'Low.png'));
    imwrite(imgRefLdr, fullfile(AlignSavePath, Scene, 'Ref.png'));
    imwrite(fI(:,:,:,3).^(1/2.2), fullfile(AlignSavePath, Scene, 'High.png'));
end
fprintf('Done!');