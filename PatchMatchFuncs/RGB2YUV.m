function Y = RGB2YUV(Img)
% input: RGB image
% output: Y,U,V channel needed
    Y = 0.299.*Img(:,:,1) + 0.587.*Img(:,:,2) + 0.114.*Img(:,:,3);
end
