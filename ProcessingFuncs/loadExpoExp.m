function Expo = loadExpoExp(path, flag)
% function for read & process expo value.
% convert expo values to exposure rate
% Arguments:
%   'path', low expo image HDR domain
%   'flag', for input data type, 0 - exposure time, 1 - f-stop
% Return:
%   processed exposure values
    expo_time_ms = '\exposure_ms.txt';
    expo = zeros(1,3);
    
    InfoFile = fullfile(path, expo_time_ms); 
    expo = textread(InfoFile);

    if(sum(expo==0))
        error('0 in read exposure!');
    end
    
    if(flag)
        % flag=1, exposure time = 2^stop
        Expo = power(2, expo);
    else
        % flag=0, convert to exposure rate
        Expo = [1, expo(2)/expo(1), expo(3)/expo(1)];
%         Expo = expo./1000;
    end
    Expo = sort(Expo);
end