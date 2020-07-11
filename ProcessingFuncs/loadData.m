function [imgSeqColor,imgRefLdr] = loadData(path, refID, reduce)
% This procedure loads a sequence of images 
% & turn into HDR domain using expo info
% Arguments:
%   'path', refers to a directory which contains a sequence of images
%   'expo', loaded txt info of expo time
%   'reduce' is an optional parameter that controls downsampling, e.g., reduce = .5
%   downsamples all images by a factor of 2.
% Return:
%   image sequence in HDR domain
%% image processing
    %== read image & convert to linear ==
    if ~exist('reduce', 'var')
        reduce = 1;
    end

    if ((reduce > 1) || (reduce <= 0))
        error('reduce must fulfill: 0 < reduce <= 1');
    end
    
    % read imgSeqLdr & allocate memory
    N = 3;
%     refView = 'view1.png';
    Exp = {'Exp0', 'Exp1' ,'Exp2'};
    ind = round(rand()); % 随机选取过曝图是refer img左侧还是右侧
    if(refID==1)
        LdrPath{1} = fullfile(path, Exp{1}, ['view' num2str(2*ind) '.png']); 
        LdrPath{2} = fullfile(path, Exp{2}, 'view1.png'); 
        LdrPath{3} = fullfile(path, Exp{3}, ['view' num2str(2*(1-ind)) '.png']); 
        fprintf('index %d %d!\n',2*ind, 2*(1-ind));
    elseif(refID==5)
        LdrPath{1} = fullfile(path, Exp{1}, ['view' num2str(refID-1+2*ind) '.png']); 
        LdrPath{2} = fullfile(path, Exp{2}, 'view5.png'); 
        LdrPath{3} = fullfile(path, Exp{3}, ['view' num2str(refID-1+2*(1-ind)) '.png']); 
        fprintf('index %d %d!\n',refID-1+2*ind, refID-1+2*(1-ind));
    end
    Ldr1 = im2double(imread(LdrPath{1}));
    sz = size(Ldr1);
    r = floor(sz(1)*reduce);
    c = floor(sz(2)*reduce);
    imgSeqColor = zeros(r,c,3,N);
    % read all files
    imgSeqColor(:,:,:,1) = Ldr1;
    for n=2:N
        imgSeqColor(:,:,:,n) = im2double(imread(LdrPath{n}));
    end
    imgRefLdr = imgSeqColor(:,:,:,2);
    % convert to linear domain -> gamma correction
    imgSeqColor = imgSeqColor.^2.2;
end