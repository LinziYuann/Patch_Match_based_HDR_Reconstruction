function [dbest1,ybest1] = improve_guessV2(imRef, imSrc, xI,yI, ybest, dbest, xp, yp, wSize,bs)
% Improve current guess->min dist
    dbest1 = dbest;
    ybest1 = ybest;
    %% compute cost function
    offset = wSize-1;
    L2 = sum((imRef(xI:xI+offset,yI:yI+offset,:) - imSrc(xp:xp+offset,yp:yp+offset,:)).^2,'all');
    c = 1 - abs(yI-yp)/bs;
    d = L2/c;
    if(L2==Inf)
        error('Distence is INF! [%f,%f]\n',sigmaRef,sigmaSrc);
    end
    if c>= 0
    %% improve d
%     if d > dbest % structure rate
        if (d <= dbest(1))&&(L2 < dbest(2))
            dbest1 = [d, L2];
            ybest1 = yp;
        end
    else
        fprintf('Warning: %f < 0! (%d, %d),(%d, %d)\n',c,xI,yI,xp,yp);
    end
%     fprintf('improve_guess dbest/ybest: %f/%d\n',dbest1,ybest1);
end