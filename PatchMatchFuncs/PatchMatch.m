function [ann, annd]=PatchMatch(imRef, imSrc, baseline,  wSize, stepSize)
% 单向patch match
%% ========================================================================
% based on patch match algorithm
% random search corresponding patches: imSrc->imRef
%% ========================================================================
    [s1, s2, ~] = size(imRef);
    xIdxMax = s1-wSize+1;
    yIdxMax = s2-wSize+1;
    % iter param
    MaxIter = 2;
    C = 0.03 ^ 2 / 2; % inherited from SSIM
    xIdx = 1 : stepSize : xIdxMax;
    xIdx = [xIdx xIdx(end)+1 : xIdxMax]; %加入边缘patch
    yIdy = 1 : stepSize : yIdxMax;
    yIdy = [yIdy yIdy(end)+1 : yIdxMax];
    xIter = length(xIdx);
    yIter = length(yIdy);
    %window = ones(wSize);
%     window3D = repmat(ones(wSize), [1, 1, 3]);
%     window3D = window3D / sum(window3D(:));
    %% Initialize with random nearest neighbor field (NNF)
    ann = zeros(xIter, yIter, 2); % x&y coor: imRef(xIdx(i),yIdx(j))->imSrc(squeeze(ann(i,j,:)))
    [X,Y] = ndgrid(xIdx, yIdy); % 初始位置为原始位置
    ann(:,:,1) = X;
    ann(:,:,2) = Y;
    % structure rate
%     crossMu = lMu(:,:,1) .* lMu(:,:,2); % lMu
%     crossSigma = convn(imRef.*imSrc, window3D, 'valid') - crossMu;
%     sMap = (crossSigma + C) ./ (sigma(:,:,1).* sigma(:,:,2) + C); % the third term in SSIM
%     annd = sMap(xIdx, yIdy);
    % structure difference L2
    annd = zeros(xIter, yIter,2);
%     annd(:,:,1) = ones(xIter, yIter);
    offSet = wSize-1;
    for m = 1:xIter
        for n = 1:yIter
            x = xIdx(m); % current iter patch
            y = yIdy(n);
            annd(m,n,:) = sum((imSrc(x:x+offSet, y:y+offSet,:) - imRef(x:x+offSet, y:y+offSet,:)).^2,'all');
        end
    end
    
    %% In each iteration, improve the NNF
    % by looping in scanline order.
    fprintf('========= begin =========\n');
    for iter = 1:MaxIter
        fprintf('iter: %d\n',iter);
        for i = 1:xIter
            for j = 1:yIter
                % Current (best) guess
                xI = xIdx(i); % current iter patch
                yI = yIdy(j);
%                 fprintf('xId:%d, yId:%d \n',xI,yI);
                ybest = ann(i,j,2);
				dbest = annd(i,j,:);
               %% Propagation: Improve current guess by trying instead
                % correspondences from left and right
                if yI==1
                    yp = ann(i,j+1,2);
                elseif yI==yIdxMax
                    yp = ann(i,j-1,2);
                else 
                    if mod(iter,2)==1
                        yp = ann(i,j-1,2);
                    else
                        yp = ann(i,j+1,2);
                    end
                end
                sR = baseline;
                %sR = 50;
                [dbest,ybest] = improve_guessV2(imRef, imSrc, xI,yI, ybest, dbest, xI, yp, wSize,sR);
               %% Random search: Improve current guess by searching in boxes 
                % of exponentially decreasing size around the current best guess
                SearchWidth = round(sR*0.8);
                while (SearchWidth >= 1) %最小精度1
%                     ymin = max(ybest1-SearchWidth,1);
%                     ymax = min(ybest1+SearchWidth+1,yIdxMax);
                    ymin = max(max(yI-sR,ybest-SearchWidth),1); % 在[yI-sR,yI+sR]范围内搜索
                    ymax = min(min(yI+sR,ybest+SearchWidth),yIdxMax);
                    if ymax>=ymin
                        Range = yIdy((yIdy>=ymin)&(yIdy<=ymax));
                        Rid = fix(rand()*length(Range))+1;
%                         fprintf('range [%d,%d], Rid: %d\n',ymin,ymax,Rid);
                        yp1 = Range(Rid);
                        [dbest,ybest] = improve_guessV2(imRef, imSrc, xI,yI, ybest, dbest, xI, yp1, wSize,sR);
%                         fprintf('dbestF/ybestF: %f/%d\n',dbestF,ybestF);
                    end
                    SearchWidth = fix(SearchWidth/2);
                end
                ann(i,j,2) = ybest;
				annd(i,j,:) = dbest;
            end
        end
    end 
end
