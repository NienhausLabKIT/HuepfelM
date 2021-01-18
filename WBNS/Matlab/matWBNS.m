function clrImg = matWBNS(Img, psfw, nlvl)

% psfw - PSF width in pixels
% nlvl - level of DWT decomposition for noise subtraction 

blvl = ceil(log2(psfw)); % level of DWT decomposition for background subtraction 
sigma = pow2(blvl);

clrImg = Img; %cleared image initialization

parfor f_idx = 1:size(Img,3)
    bkgImg = zeros(size(Img,1),size(Img,2)); %background frame initialization
    nseImg = zeros(size(Img,1),size(Img,2)); %noise frame initialization
    
    % background estimation
    if (blvl > 0)
        [cb,sb] = wavedec2(Img(:,:,f_idx), blvl, 'db1');

        cb(sb(1,1)*sb(1,2)+1:end) = 0;
        bkgImg = waverec2(cb, sb, 'db1');
        bkgImg = imgaussfilt(bkgImg,sigma);
        bkgImg(bkgImg < 0) = 0;
    end
    
    % noise estimation
    if (nlvl > 0)
        [cn,sn] = wavedec2(Img(:,:,f_idx), nlvl, 'db1');

        cn(1:sn(1,1)*sn(1,2)) = 1;
        nseImg = waverec2(cn, sn, 'db1');

        nseImg(nseImg < 0) = 0;
		nseImg(nseImg > (mean(mean(nseImg)) + 2*std(std(nseImg))) ) = (mean(mean(nseImg)) + 2*std(std(nseImg)));
    end

    clrImg(:,:,f_idx) = Img(:,:,f_idx) - bkgImg - nseImg;
end

clrImg(clrImg < 0) = 0;

