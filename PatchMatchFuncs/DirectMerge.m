 function [fI, Ann,countMap,diffy] = DirectMerge(imgSeqColor, baseline, varargin)
    % 单向patch直接融合, 低曝光直方图匹配到高曝光做match
    %% parameters
    params = inputParser;
    
    default_expo = [];
    default_wSize = 21;
    default_stepSize = max(fix(default_wSize/10),1);
    
    addRequired(params,'imgSeqColor');
    addRequired(params,'baseline');
    addParameter(params, 'expo', default_expo, @isnumeric);
    addParameter(params, 'wSize', default_wSize, @isnumeric);
    addParameter(params, 'stepSize', default_stepSize, @isnumeric);
    parse(params, imgSeqColor, baseline, varargin{:});
    
    %% initialization 
    expo = params.Results.expo;
    wSize = params.Results.wSize;
    stepSize = params.Results.stepSize;
    
    imgSeqColor = double(imgSeqColor);
    [s1, s2, s3, s4] = size(imgSeqColor); 
    xIdxMax = s1-wSize+1;
    yIdxMax = s2-wSize+1;
    refIdx = selectRef(imgSeqColor);
    
    %% generating pseudo exposures
    numExd = 2*s4-1; 
    %fprintf("numExd:%d, s4: %d",numExd,s4);
    imgSeqColorExd = zeros(s1, s2, s3, numExd);
    imgSeqColorExd(:,:,:,1:s4) = imgSeqColor;
    clear imgSeqColor;
    count = 0;
    for i = 1 : s4
        if i ~= refIdx
            count = count + 1;
            if isempty(expo)
                temp = imhistmatch(imgSeqColorExd(:,:,:,refIdx), imgSeqColorExd(:,:,:,i), 256); %把ref曝光调到非ref图
            else
                temp = imgSeqColorExd(:,:,:,refIdx)* expo(i)/ expo(refIdx);
            end
            temp( temp<0 ) = 0;
            temp( temp>1 ) = 1;
            imgSeqColorExd(:,:,:,count+s4) = temp;          
        end
    end
    
    Temp = zeros(s1, s2, s3, s4);
    Temp(:,:,:,refIdx) = imgSeqColorExd(:,:,:,refIdx);
    for i = 1 : refIdx
        tmp = imhistmatch(imgSeqColorExd(:,:,:,i), imgSeqColorExd(:,:,:,refIdx), 256); %把非ref曝光调到ref图
        tmp( tmp<0 ) = 0;
        tmp( tmp>1 ) = 1;
        Temp(:,:,:,i) = tmp;
    end
    %% patch match
    xIdx = 1 : stepSize : xIdxMax;
    xIdx = [xIdx xIdx(end)+1 : xIdxMax]; %加入边缘patch
    yIdy = 1 : stepSize : yIdxMax;
    yIdy = [yIdy yIdy(end)+1 : yIdxMax];
    xIter = length(xIdx);
    yIter = length(yIdy);
    
    Ann = zeros(xIter, yIter, 2, s4);
    [X,Y] = ndgrid(xIdx, yIdy);
    Ann(:,:,1,refIdx) = X;
    Ann(:,:,2,refIdx) = Y;
    Annd = zeros(xIter, yIter,2,s4); % (xIter, yIter, s4)
    Annd(:,:,:,refIdx) = ones(xIter, yIter,2);
    tic
    % 低曝光直方图匹配到高曝光做match
    for i = 1:s4
        if i < refIdx
            fprintf('image id: %d',i);
%             [ann, annd]=PatchMatchV2(imgSeqColorExd(:,:,:,refIdx), imgSeqColorExd(:,:,:,i), baseline, wSize, stepSize);
            [ann, annd]=PatchMatch(Temp(:,:,:,refIdx), Temp(:,:,:,i), baseline, wSize, stepSize);
%             [ann, annd]=PatchMatchV1(Temp(:,:,:,refIdx), Temp(:,:,:,i), baseline, wSize, stepSize);
            Ann(:,:,:,i) = ann;
            Annd(:,:,:,i) = annd;
        elseif i > refIdx
            [ann, annd]=PatchMatch(imgSeqColorExd(:,:,:,i+s4-1), imgSeqColorExd(:,:,:,i), baseline, wSize, stepSize);
%             [ann, annd]=PatchMatchV1(Temp(:,:,:,refIdx), Temp(:,:,:,i), baseline, wSize, stepSize);
            Ann(:,:,:,i) = ann;
            Annd(:,:,:,i) = annd;
        end
    end
    toc
    %% Ann move visualization
    diffY = Ann(:,:,2,:) - repmat(Y,1,1,1,s4);
    diffy = diffY(:,:,:,[1:refIdx-1,refIdx+1:end]);
        
    %% computing consistency map  
    fprintf('==computing consistency map==\n');
    % 欠曝/过曝区域选择原始图像patch，一致性若高选AD
    % Annd,map为1的部分选取原图像中的区域
    % structure difference L2
    sRefMap = squeeze(Annd(:,:,1,:));
    sThres = median(sRefMap,'all');
    fprintf('structure consistency max/min/median %f/%f/%f\n',max(sRefMap,[],'all'),min(sRefMap,[],'all'),sThres);
    
    %% main loop for spd-mef
    fprintf('== main loop ==\n');
    fI = zeros(s1, s2, s3,s4); 
    countMap = zeros(s1, s2, s3,s4); 
    countWindow = ones(wSize, wSize, s3);
    offset = wSize-1;
    %=== direct merge===
    for row = 1 : xIter
        for col = 1 : yIter
            xi = xIdx(row);
            yj = yIdy(col);
            sBlock = zeros(wSize, wSize, s3, s4);
            for k = 1 : s4
                if k~= refIdx
                    i = Ann(row,col,1,k);
                    j = Ann(row,col,2,k);
%                     ind = indM(row,col,k);
                    sBlock(:, :, :, k) = imgSeqColorExd(i:i+offset, j:j+offset, :, k); %(wSize, wSize, 3)原图, AD图patch二选一
                    countMap(xi:xi+offset, yj:yj+offset, :,k) = countMap(xi:xi+offset, yj:yj+offset, :,k) + countWindow;
                end
            end
            fI(xi:xi+offset, yj:yj+offset, :,:) = fI(xi:xi+offset, yj:yj+offset, :,:) + sBlock;
        end
    end
    fI = fI ./ countMap; % patch累加再平均
    fI(fI > 1) = 1;
    fI(fI < 0) = 0;
end
